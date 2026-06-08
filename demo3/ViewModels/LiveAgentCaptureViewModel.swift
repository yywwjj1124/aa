import SwiftUI
internal import Combine

#if os(iOS)
@preconcurrency import AVFoundation
import CoreImage
@preconcurrency import Speech
import UIKit
#endif

@MainActor
final class LiveAgentCaptureViewModel: ObservableObject {
    @Published var captureState: AgentCaptureState = .starting
    @Published var micLevel: CGFloat = 0.18
    @Published var transcript = "正在打开摄像头与麦克风..."
    @Published var agentDecision = "Voxen Agent 正在等待端侧信号"
    @Published var detectedSpeechLanguageLabel = "语言自动识别"
    @Published var latestIncident: IncidentItem?
    
    private var hasStarted = false
    private weak var agentStore: AgentIncidentStore?
    private let agentClient: AgentAPIClient
    private let senseVoiceClient: SenseVoiceSpeechClient
    private let localIncidentAnalyzer: LocalIncidentAnalyzer
    private var latestVisionFrameBase64: String?
    private var agentDebounceTask: Task<Void, Never>?
    private var transcriptStabilizationTask: Task<Void, Never>?
    private var candidateTranscript = ""
    private var lastPublishedTranscript = ""
    private var lastAgentPublishDate = Date.distantPast
    private var activeSpeechLanguage = AgentSpeechLanguageProfile.mandarin
    private var isSenseVoiceRequestInFlight = false
    
    #if os(iOS)
    private let cameraController = CameraSessionController()
    private let audioEngine = AVAudioEngine()
    private let speechRequestProxy = SpeechAudioRequestProxy()
    private let speechChunker = SpeechAudioChunker()
    private var speechRecognizer: SFSpeechRecognizer?
    private var speechRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechTask: SFSpeechRecognitionTask?
    private var isCameraConfigured = false
    private var isAudioTapInstalled = false
    private var canUseSystemSpeech = false
    
    var cameraSession: AVCaptureSession {
        cameraController.session
    }
    #endif
    
    init() {
        self.agentClient = AgentAPIClient()
        self.senseVoiceClient = SenseVoiceSpeechClient()
        self.localIncidentAnalyzer = LocalIncidentAnalyzer()
    }
    
    init(agentClient: AgentAPIClient, senseVoiceClient: SenseVoiceSpeechClient) {
        self.agentClient = agentClient
        self.senseVoiceClient = senseVoiceClient
        self.localIncidentAnalyzer = LocalIncidentAnalyzer()
    }
    
    func start(agentStore: AgentIncidentStore) {
        guard !hasStarted else { return }
        self.agentStore = agentStore
        hasStarted = true
        
        #if os(iOS)
        requestCaptureAccess(agentStore: agentStore)
        #else
        startPreviewSimulation(agentStore: agentStore)
        #endif
    }
    
    func stop() {
        hasStarted = false
        agentDebounceTask?.cancel()
        transcriptStabilizationTask?.cancel()
        
        #if os(iOS)
        cameraController.stop()
        speechRequest?.endAudio()
        speechRequestProxy.update(nil)
        speechChunker.reset()
        speechTask?.cancel()
        speechTask = nil
        speechRequest = nil
        if isAudioTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isAudioTapInstalled = false
        }
        audioEngine.stop()
        #endif
    }
    
    private func runDemoAgentRecognition(agentStore: AgentIncidentStore) {
        Task { @MainActor in
            captureState = .listening
            transcript = "阿叔：呢度贴膜起泡泡啦，呢批货都有问题，你快来看下。"
            agentDecision = "端侧 SLM 正在抽取：工位、异常类型、批次风险"
            
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            
            captureState = .analyzing
            agentDecision = "Agent 正在融合语音与视觉信号"
            
            let incident = await recognizeWithConfiguredAgent() ?? simulatedIncident()
            
            latestIncident = incident
            captureState = .detected
            agentDecision = "已发布异常到状态中心：\(incident.ticketNumber)"
            agentStore.publish(incident)
        }
    }
    
    private func startPreviewSimulation(agentStore: AgentIncidentStore) {
        captureState = .listening
        animateMockMicLevel()
        runDemoAgentRecognition(agentStore: agentStore)
    }
    
    private func animateMockMicLevel() {
        Task { @MainActor in
            while hasStarted {
                withAnimation(.easeInOut(duration: 0.28)) {
                    micLevel = CGFloat.random(in: 0.18...0.92)
                }
                try? await Task.sleep(nanoseconds: 280_000_000)
            }
        }
    }
    
    #if os(iOS)
    private func requestCaptureAccess(agentStore: AgentIncidentStore) {
        Task { @MainActor in
            let cameraGranted = await Self.requestCameraPermission()
            let micGranted = await Self.requestMicrophonePermission()
            let speechGranted = await Self.requestSpeechPermission()
            
            guard cameraGranted && micGranted else {
                captureState = .permissionDenied
                transcript = "需要摄像头与麦克风权限，才能进行视觉/语音异常识别。"
                agentDecision = "权限未授权，Agent 识别暂停"
                return
            }
            
            canUseSystemSpeech = speechGranted
            configureCameraIfNeeded()
            startCamera()
            startSpeechRecognition(agentStore: agentStore)
        }
    }
    
    private func configureCameraIfNeeded() {
        guard !isCameraConfigured else { return }
        isCameraConfigured = true
        cameraController.configure()
    }
    
    private func startCamera() {
        cameraController.start()
    }
    
    private func startSpeechRecognition(agentStore: AgentIncidentStore) {
        guard !isAudioTapInstalled else { return }
        isAudioTapInstalled = true
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
            
            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            if canUseSystemSpeech && !senseVoiceClient.isConfigured {
                startSpeechTask()
            }
            let requestProxy = speechRequestProxy
            let speechChunker = speechChunker
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self, requestProxy, speechChunker] buffer, _ in
                requestProxy.append(buffer)
                let speechChunk = speechChunker.append(buffer)
                
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)
                guard frameLength > 0 else { return }
                
                var sum: Float = 0
                for index in 0..<frameLength {
                    sum += abs(channelData[index])
                }
                let average = min(max(CGFloat(sum / Float(frameLength)) * 18, 0.05), 1.0)
                
                Task { @MainActor in
                    self?.micLevel = average
                }
                
                if let speechChunk {
                    Task { @MainActor in
                        await self?.recognizeSpeechChunkWithSenseVoice(speechChunk)
                    }
                }
            }
            
            try audioEngine.start()
            captureState = .listening
            transcript = "正在监听现场语音..."
            detectedSpeechLanguageLabel = senseVoiceClient.isConfigured ? "SenseVoice Auto" : "系统 Speech 兜底"
            agentDecision = senseVoiceClient.isConfigured ? "SenseVoice-Small 正在进行方言 LID 与稳定转写" : "SenseVoice 未配置，使用系统 Speech 稳定转写"
        } catch {
            micLevel = 0.22
            agentDecision = "语音识别启动失败，请检查麦克风权限"
        }
    }
    
    private func startSpeechTask() {
        speechTask?.cancel()
        speechTask = nil
        speechRequest?.endAudio()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        speechRequest = request
        speechRequestProxy.update(request)
        
        let profile = AgentSpeechLanguageProfile.mandarin
        activeSpeechLanguage = profile
        detectedSpeechLanguageLabel = "系统 Speech"
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: profile.localeIdentifier))
        
        speechTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            let recognizedText = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal == true
            let hasError = error != nil
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                if let recognizedText, !recognizedText.isEmpty {
                    self.commitStableTranscript(recognizedText, languageLabel: "系统 Speech", immediate: isFinal)
                    if isFinal && self.hasStarted {
                        self.startSpeechTask()
                    }
                } else if hasError {
                    self.speechTask = nil
                    if self.hasStarted && !self.senseVoiceClient.isConfigured {
                        self.agentDecision = "正在恢复系统 Speech 监听"
                        Task { @MainActor [weak self] in
                            try? await Task.sleep(nanoseconds: 450_000_000)
                            guard let self, self.hasStarted else { return }
                            self.startSpeechTask()
                        }
                    }
                }
            }
        }
    }
    
    private func recognizeSpeechChunkWithSenseVoice(_ chunk: SpeechAudioChunk) async {
        guard senseVoiceClient.isConfigured else { return }
        guard !isSenseVoiceRequestInFlight else { return }
        isSenseVoiceRequestInFlight = true
        defer { isSenseVoiceRequestInFlight = false }
        
        do {
            let result = try await senseVoiceClient.recognize(
                wavAudioBase64: chunk.wavData.base64EncodedString(),
                sampleRate: chunk.sampleRate
            )
            commitStableTranscript(
                result.text,
                languageLabel: result.language ?? result.languageCode ?? "SenseVoice Auto",
                immediate: false
            )
        } catch {
            agentDecision = "SenseVoice 暂时不可用，正在切换系统 Speech"
            if canUseSystemSpeech && speechTask == nil && hasStarted {
                startSpeechTask()
            }
        }
    }
    
    private func commitStableTranscript(_ rawText: String, languageLabel: String, immediate: Bool) {
        let normalizedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedText.count >= 3 else { return }
        guard normalizedText != candidateTranscript else { return }
        
        candidateTranscript = normalizedText
        transcriptStabilizationTask?.cancel()
        transcriptStabilizationTask = Task { @MainActor in
            if !immediate {
                try? await Task.sleep(nanoseconds: 850_000_000)
            }
            
            let inferredLanguage = inferSpeechLanguage(from: normalizedText, fallbackLabel: languageLabel)
            activeSpeechLanguage = inferredLanguage
            detectedSpeechLanguageLabel = inferredLanguage.displayName
            transcript = normalizedText
            agentDecision = "稳定译轨已生成，Agent 正在判定异常"
            scheduleAgentRecognition(immediate: immediate)
        }
    }
    
    private func inferSpeechLanguage(from text: String, fallbackLabel: String) -> AgentSpeechLanguageProfile {
        let lowercasedText = text.lowercased()
        let lowercasedLabel = fallbackLabel.lowercased()
        let cantoneseMarkers = ["唔", "咗", "喺", "噉", "咁", "呢度", "嗰", "冇", "嘅", "啱"]
        let sichuanMarkers = ["要得", "啥子", "莫得", "巴适", "安逸", "瓜", "整不成", "搞快"]
        let vietnameseMarkers = ["không", "máy", "lỗi", "hết", "vật liệu", "bong bóng", "kiểm tra", "đang"]
        
        if lowercasedLabel.contains("vi") || lowercasedLabel.contains("越南") || vietnameseMarkers.contains(where: { lowercasedText.contains($0) }) {
            return .vietnamese
        }
        
        if lowercasedLabel.contains("en") || lowercasedLabel.contains("english") || lowercasedText.range(of: "[a-z]{3,}", options: .regularExpression) != nil {
            return .english
        }
        
        if lowercasedLabel.contains("yue") || lowercasedLabel.contains("cantonese") || fallbackLabel.contains("粤") || cantoneseMarkers.contains(where: { text.contains($0) }) {
            return .cantonese
        }
        
        if fallbackLabel.contains("四川") || fallbackLabel.contains("西南") || sichuanMarkers.contains(where: { text.contains($0) }) {
            return AgentSpeechLanguageProfile(
                localeIdentifier: AgentSpeechLanguageProfile.mandarin.localeIdentifier,
                displayName: "四川话",
                agentHint: "四川话/西南官话现场提报，请结合上下文转成标准中文工单描述"
            )
        }
        
        if lowercasedLabel.contains("zh") || fallbackLabel.contains("中文") || fallbackLabel.contains("普通话") {
            return .mandarin
        }
        
        return AgentSpeechLanguageProfile(
            localeIdentifier: "auto",
            displayName: fallbackLabel.isEmpty ? "SenseVoice Auto" : fallbackLabel,
            agentHint: "SenseVoice-Small 自动语种/方言识别结果，请结合文本归一为标准中文工单描述"
        )
    }
    
    private static func requestCameraPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    private static func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    #endif
    
    private func scheduleAgentRecognition(immediate: Bool) {
        let normalizedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedTranscript.count >= 6 else { return }
        guard normalizedTranscript != lastPublishedTranscript else { return }
        guard Date().timeIntervalSince(lastAgentPublishDate) > 4 else { return }
        
        agentDebounceTask?.cancel()
        agentDebounceTask = Task { @MainActor in
            if !immediate {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
            await publishRecognizedIncident()
        }
    }
    
    private func publishRecognizedIncident() async {
        guard let agentStore else { return }
        let sourceTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard sourceTranscript.count >= 6 else { return }
        guard sourceTranscript != lastPublishedTranscript else { return }
        
        captureState = .analyzing
        agentDecision = "Agent 正在融合语言/方言、语音与视觉信号"
        
        guard let incident = await recognizeWithConfiguredAgent() else {
            captureState = .listening
            return
        }
        
        latestIncident = incident
        captureState = .detected
        agentDecision = "已发布异常到状态中心：\(incident.ticketNumber)"
        lastPublishedTranscript = sourceTranscript
        lastAgentPublishDate = Date()
        agentStore.publish(incident)
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if captureState == .detected {
                captureState = .listening
                agentDecision = "继续监听新的语言/方言异常提报"
            }
        }
    }
    
    private func recognizeWithConfiguredAgent() async -> IncidentItem? {
        let localDecision = localIncidentAnalyzer.analyze(
            transcript: transcript,
            speechLanguage: activeSpeechLanguage,
            micLevel: Double(micLevel)
        )
        
        if let localDecision, localDecision.confidence >= 0.82 {
            agentDecision = "端侧已完成高置信度判定，无需等待云端"
            return makeIncident(
                from: localDecision.response,
                decisionSource: "Voxen Edge 本地规则引擎",
                confidence: localDecision.confidence
            )
        }
        
        do {
            let response = try await agentClient.recognize(
                transcript: transcript,
                speechLanguage: activeSpeechLanguage,
                micLevel: Double(micLevel),
                visionFrameBase64: currentVisionFrameBase64()
            )
            
            guard response.detected else {
                if let localDecision, localDecision.confidence >= 0.66 {
                    agentDecision = "云端未确认，采用端侧可解释判定并等待人工复核"
                    return makeIncident(
                        from: localDecision.response,
                        decisionSource: "Voxen Edge 本地规则引擎",
                        confidence: localDecision.confidence
                    )
                }
                agentDecision = "Agent 暂未判定异常，继续监听现场"
                return nil
            }
            
            return makeIncident(
                from: response,
                decisionSource: "Voxen 多模态云端 Agent",
                confidence: response.confidence
            )
        } catch AgentAPIError.missingConfig {
            guard let localDecision, localDecision.confidence >= 0.58 else {
                agentDecision = "未配置云端 Agent，端侧继续监听"
                return nil
            }
            agentDecision = "当前离线，已由端侧完成异常初判"
            return makeIncident(
                from: localDecision.response,
                decisionSource: "Voxen Edge 离线规则引擎",
                confidence: localDecision.confidence
            )
        } catch {
            guard let localDecision, localDecision.confidence >= 0.58 else {
                agentDecision = "Agent 接口暂不可用，端侧未发现明确异常"
                return nil
            }
            agentDecision = "网络不可用，已切换端侧判定"
            return makeIncident(
                from: localDecision.response,
                decisionSource: "Voxen Edge 离线规则引擎",
                confidence: localDecision.confidence
            )
        }
    }
    
    private func makeIncident(
        from response: AgentRecognitionResponse,
        decisionSource: String,
        confidence: Double?
    ) -> IncidentItem {
        let confidenceText = confidence.map { String(format: "%.0f%%", $0 * 100) } ?? "待复核"
        let sourceDetail = "\(decisionSource)完成判定，置信度 \(confidenceText)。"
        let responseDetail = response.details ?? "已根据摄像头、麦克风和工位上下文生成异常处置草稿。"
        
        return IncidentItem(
            category: response.category ?? "Agent 识别异常",
            categoryIcon: response.categoryIcon ?? incidentIcon(for: response),
            categoryColor: incidentColor(for: response),
            originalDialect: response.originalLanguage.map { "【\($0)】\(transcript)" } ?? "【\(activeSpeechLanguage.displayName)】\(transcript)",
            translatedText: response.translatedText ?? response.normalizedTranscript ?? "Agent 已完成多模态异常识别。",
            location: response.location ?? "车间 A 区 · A-03 贴膜工位",
            initiator: response.initiator ?? "现场员工 (\(detectedSpeechLanguageLabel)偏好)",
            targetSystem: response.targetSystem ?? "Voxen Agent 异常分派模块",
            ticketNumber: response.ticketNumber ?? "Live #AGENT-\(Int(Date().timeIntervalSince1970))",
            details: "\(sourceDetail)\(responseDetail)",
            flowNodeTitle: response.flowNodeTitle ?? "查看实时 Agent 判定证据",
            flowNodeIcon: "camera.viewfinder"
        )
    }
    
    private func currentVisionFrameBase64() -> String? {
        #if os(iOS)
        return cameraController.latestFrameBase64
        #else
        return latestVisionFrameBase64
        #endif
    }
    
    private func incidentIcon(for response: AgentRecognitionResponse) -> String {
        let text = "\(response.category ?? "") \(response.targetSystem ?? "") \(response.translatedText ?? "")"
        
        if text.localizedCaseInsensitiveContains("IT") || text.contains("终端") || text.contains("电脑") || text.contains("扫码") {
            return "laptopcomputer"
        }
        if text.localizedCaseInsensitiveContains("WMS") || text.contains("物料") || text.contains("仓储") || text.contains("缺料") {
            return "shippingbox.fill"
        }
        if text.localizedCaseInsensitiveContains("EAM") || text.contains("机修") || text.contains("设备") || text.contains("机台") {
            return "gearshape.2.fill"
        }
        if text.localizedCaseInsensitiveContains("MES") || text.localizedCaseInsensitiveContains("QA") || text.contains("品控") || text.contains("质量") || text.contains("外观") {
            return "checkmark.seal.fill"
        }
        return "exclamationmark.triangle.fill"
    }
    
    private func incidentColor(for response: AgentRecognitionResponse) -> Color {
        let text = "\(response.category ?? "") \(response.targetSystem ?? "") \(response.translatedText ?? "")"
        
        if text.localizedCaseInsensitiveContains("IT") || text.contains("终端") || text.contains("电脑") || text.contains("扫码") {
            return .blue
        }
        if text.localizedCaseInsensitiveContains("WMS") || text.contains("物料") || text.contains("仓储") || text.contains("缺料") {
            return .t2WarnOrange
        }
        if text.localizedCaseInsensitiveContains("EAM") || text.contains("机修") || text.contains("设备") || text.contains("机台") {
            return .t2WarnRed
        }
        if text.localizedCaseInsensitiveContains("MES") || text.localizedCaseInsensitiveContains("QA") || text.contains("品控") || text.contains("质量") || text.contains("外观") {
            return .t2QcPurple
        }
        return .t2Cyan
    }
    
    private func simulatedIncident() -> IncidentItem {
        IncidentItem(
            category: "产品外观不良",
            categoryIcon: "checkmark.seal.fill",
            categoryColor: .t2QcPurple,
            originalDialect: "“贴膜起泡泡啦，呢批货都有问题，你快来看下。”",
            translatedText: "端侧 Vision 检测到覆膜表面多处气泡，语音提报与视觉 ROI 一致，判定为批次性外观异常。",
            location: "车间 A 区 · A-03 贴膜工位",
            initiator: "张大叔 (贴膜班组 · 粤语偏好)",
            targetSystem: "MES 生产执行系统品控模块",
            ticketNumber: "Live #AGENT-2606",
            details: "Agent 已融合摄像头 ROI、实时语音译轨与工位 NFC 上下文，生成临时批次拦截建议并发布到状态中心，等待 QC 主管复核。",
            flowNodeTitle: "查看实时 Vision ROI 与拦截建议",
            flowNodeIcon: "camera.viewfinder"
        )
    }
}

#if os(iOS)
struct SpeechAudioChunk: Sendable {
    let wavData: Data
    let sampleRate: Int
}

nonisolated private final class CameraSessionController: @unchecked Sendable {
    let session = AVCaptureSession()
    
    private let queue = DispatchQueue(label: "voxen.camera.session.queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let frameBuffer: VisionFrameBuffer
    private let frameSampler: CameraFrameSampler
    private let frameQueue = DispatchQueue(label: "voxen.camera.frame.sample.queue")
    private var isConfigured = false
    
    init() {
        let frameBuffer = VisionFrameBuffer()
        self.frameBuffer = frameBuffer
        self.frameSampler = CameraFrameSampler(frameBuffer: frameBuffer)
    }
    
    var latestFrameBase64: String? {
        frameBuffer.latestFrameBase64
    }
    
    func configure() {
        queue.async { [self] in
            guard !isConfigured else { return }
            isConfigured = true
            
            session.beginConfiguration()
            session.sessionPreset = .high
            
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let input = try? AVCaptureDeviceInput(device: device),
               session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(videoOutput) {
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.setSampleBufferDelegate(frameSampler, queue: frameQueue)
                session.addOutput(videoOutput)
            }
            
            session.commitConfiguration()
        }
    }
    
    func start() {
        queue.async { [self] in
            guard !session.isRunning else { return }
            session.startRunning()
        }
    }
    
    func stop() {
        queue.async { [self] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }
}

nonisolated private final class VisionFrameBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var storedFrameBase64: String?
    
    var latestFrameBase64: String? {
        lock.lock()
        let frame = storedFrameBase64
        lock.unlock()
        return frame
    }
    
    func update(_ frameBase64: String) {
        lock.lock()
        storedFrameBase64 = frameBase64
        lock.unlock()
    }
}

nonisolated private final class SpeechAudioRequestProxy: @unchecked Sendable {
    private let lock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    
    func update(_ request: SFSpeechAudioBufferRecognitionRequest?) {
        lock.lock()
        self.request = request
        lock.unlock()
    }
    
    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let request = request
        lock.unlock()
        request?.append(buffer)
    }
}

nonisolated private final class SpeechAudioChunker: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Int16] = []
    private var sampleRate = 16_000
    private var lastEmitTime = Date.distantPast
    private var accumulatedAmplitude: Double = 0
    private var accumulatedFrameCount = 0
    
    func reset() {
        lock.lock()
        samples.removeAll(keepingCapacity: false)
        accumulatedAmplitude = 0
        accumulatedFrameCount = 0
        lastEmitTime = .distantPast
        lock.unlock()
    }
    
    func append(_ buffer: AVAudioPCMBuffer) -> SpeechAudioChunk? {
        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            return nil
        }
        
        let bufferSampleRate = Int(buffer.format.sampleRate.rounded())
        var emittedChunk: SpeechAudioChunk?
        
        lock.lock()
        sampleRate = max(bufferSampleRate, 8_000)
        
        for index in 0..<frameLength {
            let clippedSample = max(-1.0, min(1.0, channelData[index]))
            samples.append(Int16(clippedSample * Float(Int16.max)))
            accumulatedAmplitude += Double(abs(clippedSample))
        }
        accumulatedFrameCount += frameLength
        
        let minimumFrames = sampleRate
        let maximumFrames = Int(Double(sampleRate) * 2.8)
        let shouldEmit = samples.count >= maximumFrames && Date().timeIntervalSince(lastEmitTime) > 2.4
        
        if shouldEmit && samples.count >= minimumFrames {
            let segmentSamples = samples
            let averageAmplitude = accumulatedFrameCount > 0
                ? accumulatedAmplitude / Double(accumulatedFrameCount)
                : 0
            samples.removeAll(keepingCapacity: true)
            accumulatedAmplitude = 0
            accumulatedFrameCount = 0
            lastEmitTime = Date()
            
            if averageAmplitude >= 0.008 {
                emittedChunk = SpeechAudioChunk(
                    wavData: Self.makeWavData(samples: segmentSamples, sampleRate: sampleRate),
                    sampleRate: sampleRate
                )
            }
        }
        
        lock.unlock()
        return emittedChunk
    }
    
    private static func makeWavData(samples: [Int16], sampleRate: Int) -> Data {
        let channelCount: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = UInt32(sampleRate) * UInt32(channelCount) * UInt32(bitsPerSample / 8)
        let blockAlign = channelCount * bitsPerSample / 8
        let dataSize = UInt32(samples.count * MemoryLayout<Int16>.size)
        let riffSize = UInt32(36) + dataSize
        
        var data = Data()
        data.appendASCII("RIFF")
        data.appendLittleEndian(riffSize)
        data.appendASCII("WAVE")
        data.appendASCII("fmt ")
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(channelCount)
        data.appendLittleEndian(UInt32(sampleRate))
        data.appendLittleEndian(byteRate)
        data.appendLittleEndian(blockAlign)
        data.appendLittleEndian(bitsPerSample)
        data.appendASCII("data")
        data.appendLittleEndian(dataSize)
        
        samples.forEach { data.appendLittleEndian($0) }
        return data
    }
}

private extension Data {
    nonisolated mutating func appendASCII(_ value: String) {
        append(contentsOf: value.utf8)
    }
    
    nonisolated mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { bytes in
            append(contentsOf: bytes)
        }
    }
}

nonisolated private final class CameraFrameSampler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let context = CIContext()
    private let frameBuffer: VisionFrameBuffer
    private var lastEmitTime = Date.distantPast
    
    init(frameBuffer: VisionFrameBuffer) {
        self.frameBuffer = frameBuffer
    }
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard Date().timeIntervalSince(lastEmitTime) > 1.0 else {
            return
        }
        lastEmitTime = Date()
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        
        let image = UIImage(cgImage: cgImage)
        guard let jpegData = image.jpegData(compressionQuality: 0.45) else {
            return
        }
        
        frameBuffer.update(jpegData.base64EncodedString())
    }
}
#endif
