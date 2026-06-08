import SwiftUI
internal import Combine

// MARK: - Agent 实时识别状态
enum AgentCaptureState: Equatable {
    case starting
    case listening
    case analyzing
    case detected
    case permissionDenied
}

// MARK: - Speech 方言/语言候选
struct AgentSpeechLanguageProfile: Identifiable, Equatable {
    let id: String
    let localeIdentifier: String
    let displayName: String
    let agentHint: String
    
    init(localeIdentifier: String, displayName: String, agentHint: String) {
        self.id = localeIdentifier
        self.localeIdentifier = localeIdentifier
        self.displayName = displayName
        self.agentHint = agentHint
    }
    
    static let mandarin = AgentSpeechLanguageProfile(
        localeIdentifier: "zh-CN",
        displayName: "普通话",
        agentHint: "普通话或带四川、华南口音的中文现场提报"
    )
    
    static let cantonese = AgentSpeechLanguageProfile(
        localeIdentifier: "zh-HK",
        displayName: "粤语",
        agentHint: "粤语/广东话现场提报，请保留方言原意并转成标准工单描述"
    )
    
    static let cantoneseYue = AgentSpeechLanguageProfile(
        localeIdentifier: "yue-Hans-CN",
        displayName: "粤语",
        agentHint: "粤语/广东话现场提报，请保留方言原意并转成标准工单描述"
    )
    
    static let english = AgentSpeechLanguageProfile(
        localeIdentifier: "en-US",
        displayName: "English",
        agentHint: "English shop-floor report, translate and normalize into Chinese incident text"
    )
    
    static let vietnamese = AgentSpeechLanguageProfile(
        localeIdentifier: "vi-VN",
        displayName: "Tiếng Việt",
        agentHint: "Vietnamese shop-floor report, translate and normalize into Chinese incident text"
    )
    
    static let supportedCandidates: [AgentSpeechLanguageProfile] = [
        .mandarin,
        .cantonese,
        .cantoneseYue,
        .english,
        .vietnamese
    ]
}

// MARK: - SenseVoice 语音理解结果
struct SenseVoiceSpeechResult: Decodable {
    let text: String
    let language: String?
    let languageCode: String?
    let emotion: String?
    let audioEvent: String?
    let confidence: Double?
    
    enum CodingKeys: String, CodingKey {
        case text
        case language
        case languageCode = "language_code"
        case emotion
        case audioEvent = "audio_event"
        case confidence
    }
}

// MARK: - Agent 发布到状态中心的共享异常池
@MainActor
final class AgentIncidentStore: ObservableObject {
    @Published private(set) var publishedIncidents: [IncidentItem] = []
    
    var latestIncident: IncidentItem? {
        publishedIncidents.first
    }
    
    func publish(_ incident: IncidentItem) {
        guard !publishedIncidents.contains(where: { $0.ticketNumber == incident.ticketNumber }) else {
            return
        }
        publishedIncidents.insert(incident, at: 0)
    }
}
