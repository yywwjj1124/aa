import Foundation

// MARK: - Agent API 配置
struct AgentAPIConfig {
    let endpointURL: URL
    let apiKey: String
    let model: String
    
    static func load() -> AgentAPIConfig? {
        if let config = loadFromSecretsPlist() {
            return config
        }
        
        guard
            let endpoint = Bundle.main.object(forInfoDictionaryKey: "VOXEN_AGENT_ENDPOINT") as? String,
            let endpointURL = URL(string: endpoint),
            let apiKey = Bundle.main.object(forInfoDictionaryKey: "VOXEN_AGENT_API_KEY") as? String
        else {
            return nil
        }
        
        let model = Bundle.main.object(forInfoDictionaryKey: "VOXEN_AGENT_MODEL") as? String ?? "voxen-agent"
        return AgentAPIConfig(endpointURL: endpointURL, apiKey: apiKey, model: model)
    }
    
    private static func loadFromSecretsPlist() -> AgentAPIConfig? {
        guard
            let url = Bundle.main.url(forResource: "AgentSecrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
            let endpoint = plist["VOXEN_AGENT_ENDPOINT"] as? String,
            let endpointURL = URL(string: endpoint),
            let apiKey = plist["VOXEN_AGENT_API_KEY"] as? String
        else {
            return nil
        }
        
        let model = plist["VOXEN_AGENT_MODEL"] as? String ?? "voxen-agent"
        return AgentAPIConfig(endpointURL: endpointURL, apiKey: apiKey, model: model)
    }
}

// MARK: - Agent 识别请求/响应
struct AgentRecognitionRequest: Encodable {
    let model: String
    let messages: [AgentChatMessage]
    let temperature: Double
    let responseFormat: AgentResponseFormat
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case responseFormat = "response_format"
    }
}

struct AgentChatMessage: Encodable {
    let role: String
    let content: AgentMessageContent
}

enum AgentMessageContent: Encodable {
    case text(String)
    case parts([AgentMessagePart])
    
    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .parts(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }
}

enum AgentMessagePart: Encodable {
    case text(String)
    case imageURL(String, detail: String)
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageURL = "image_url"
    }
    
    enum ImageURLKeys: String, CodingKey {
        case url
        case detail
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .imageURL(let url, let detail):
            try container.encode("image_url", forKey: .type)
            var imageContainer = container.nestedContainer(keyedBy: ImageURLKeys.self, forKey: .imageURL)
            try imageContainer.encode(url, forKey: .url)
            try imageContainer.encode(detail, forKey: .detail)
        }
    }
}

struct AgentResponseFormat: Encodable {
    let type: String
}

struct AgentRecognitionResponse: Decodable {
    let detected: Bool
    let originalLanguage: String?
    let normalizedTranscript: String?
    let category: String?
    let categoryIcon: String?
    let translatedText: String?
    let location: String?
    let initiator: String?
    let targetSystem: String?
    let ticketNumber: String?
    let details: String?
    let flowNodeTitle: String?
    let confidence: Double?
}

enum AgentAPIError: Error {
    case missingConfig
    case invalidResponse
}

// MARK: - 真实 Agent API 客户端
final class AgentAPIClient {
    private let config: AgentAPIConfig?
    private let urlSession: URLSession
    
    init(config: AgentAPIConfig? = AgentAPIConfig.load(), urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }
    
    func recognize(transcript: String, speechLanguage: AgentSpeechLanguageProfile, micLevel: Double, visionFrameBase64: String?) async throws -> AgentRecognitionResponse {
        guard let config else {
            throw AgentAPIError.missingConfig
        }
        
        let endpointURL = chatCompletionsURL(from: config.endpointURL)
        let body = AgentRecognitionRequest(
            model: config.model,
            messages: [
                AgentChatMessage(role: "system", content: .text(Self.systemPrompt)),
                AgentChatMessage(role: "user", content: userContent(transcript: transcript, speechLanguage: speechLanguage, micLevel: micLevel, visionFrameBase64: visionFrameBase64))
            ],
            temperature: 0.2,
            responseFormat: AgentResponseFormat(type: "json_object")
        )
        
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AgentAPIError.invalidResponse
        }
        
        let completion = try JSONDecoder().decode(SiliconFlowChatCompletion.self, from: data)
        guard let content = completion.choices.first?.message.content,
              let contentData = Self.extractJSONObject(from: content).data(using: .utf8) else {
            throw AgentAPIError.invalidResponse
        }
        
        return try JSONDecoder().decode(AgentRecognitionResponse.self, from: contentData)
    }
    
    private static func extractJSONObject(from content: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let startIndex = trimmedContent.firstIndex(of: "{"),
              let endIndex = trimmedContent.lastIndex(of: "}") else {
            return trimmedContent
        }
        return String(trimmedContent[startIndex...endIndex])
    }
    
    private func chatCompletionsURL(from baseURL: URL) -> URL {
        let urlString = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if urlString.hasSuffix("/chat/completions") {
            return baseURL
        }
        return URL(string: "\(urlString)/chat/completions") ?? baseURL
    }
    
    private func userContent(transcript: String, speechLanguage: AgentSpeechLanguageProfile, micLevel: Double, visionFrameBase64: String?) -> AgentMessageContent {
        let prompt = """
        端侧候选语言/方言：\(speechLanguage.displayName)
        端侧候选 locale：\(speechLanguage.localeIdentifier)
        方言提示：\(speechLanguage.agentHint)
        现场语音原始译轨：\(transcript)
        工位：车间 A 区 · A-03 贴膜工位
        端侧麦克风音量：\(String(format: "%.2f", micLevel))
        视觉帧是否存在：\(visionFrameBase64 == nil ? "false" : "true")
        
        请先自动判断真实语言/方言（普通话、粤语、四川话、英语、越南语或其他），再把语音内容翻译/归一为中文工业异常描述，并结合视觉帧判断是否存在工业现场异常。如果存在，按 JSON 输出：
        {
          "detected": true,
          "originalLanguage": "识别到的真实语言或方言",
          "normalizedTranscript": "归一化后的中文语义译轨",
          "category": "异常分类",
          "categoryIcon": "合适的 SF Symbol 名称",
          "translatedText": "标准化异常描述",
          "location": "物理工位",
          "initiator": "提报人描述",
          "targetSystem": "目标业务系统",
          "ticketNumber": "临时单号",
          "details": "Agent 派发细节",
          "flowNodeTitle": "状态详情页 CTA 文案",
          "confidence": 0.0
        }
        如无异常，输出 {"detected": false}
        """
        
        guard let visionFrameBase64 else {
            return .text(prompt)
        }
        
        return .parts([
            .text(prompt),
            .imageURL("data:image/jpeg;base64,\(visionFrameBase64)", detail: "low")
        ])
    }
    
    private static let systemPrompt = """
    你是 Voxen 工业现场多模态异常识别 Agent。你需要融合摄像头视觉线索、麦克风语音译轨和工位上下文，自动识别普通话、粤语、四川话、英语、越南语等语言/方言，把原始提报归一为中文工单语义，判断是否出现工厂异常，并输出严格 JSON，不要输出 Markdown。ticketNumber 必须短且唯一，categoryIcon 必须是常见 SF Symbol，例如 shippingbox.fill、gearshape.2.fill、checkmark.seal.fill、laptopcomputer、exclamationmark.triangle.fill。
    """
}

private struct SiliconFlowChatCompletion: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String
    }
}
