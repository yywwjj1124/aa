import Foundation

// MARK: - SenseVoice Small 配置
struct SenseVoiceAPIConfig {
    let endpointURL: URL
    let apiKey: String?
    let model: String
    
    static func load() -> SenseVoiceAPIConfig? {
        if let config = loadFromSecretsPlist() {
            return config
        }
        
        guard
            let endpoint = Bundle.main.object(forInfoDictionaryKey: "VOXEN_SENSEVOICE_ENDPOINT") as? String,
            let endpointURL = URL(string: endpoint)
        else {
            return nil
        }
        
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "VOXEN_SENSEVOICE_API_KEY") as? String
        let model = Bundle.main.object(forInfoDictionaryKey: "VOXEN_SENSEVOICE_MODEL") as? String ?? "FunAudioLLM/SenseVoiceSmall"
        return SenseVoiceAPIConfig(endpointURL: endpointURL, apiKey: apiKey, model: model)
    }
    
    private static func loadFromSecretsPlist() -> SenseVoiceAPIConfig? {
        guard
            let url = Bundle.main.url(forResource: "AgentSecrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
            let endpoint = plist["VOXEN_SENSEVOICE_ENDPOINT"] as? String,
            let endpointURL = URL(string: endpoint)
        else {
            return nil
        }
        
        let apiKey = plist["VOXEN_SENSEVOICE_API_KEY"] as? String
        let model = plist["VOXEN_SENSEVOICE_MODEL"] as? String ?? "FunAudioLLM/SenseVoiceSmall"
        return SenseVoiceAPIConfig(endpointURL: endpointURL, apiKey: apiKey, model: model)
    }
}

struct SenseVoiceRecognitionRequest: Encodable {
    let model: String
    let audio: String
    let sampleRate: Int
    let language: String
    let task: String
    
    enum CodingKeys: String, CodingKey {
        case model
        case audio
        case sampleRate = "sample_rate"
        case language
        case task
    }
}

enum SenseVoiceAPIError: Error {
    case missingConfig
    case invalidResponse
}

// MARK: - SenseVoice Small ASR + LID 客户端
final class SenseVoiceSpeechClient {
    private let config: SenseVoiceAPIConfig?
    private let urlSession: URLSession
    
    init(config: SenseVoiceAPIConfig? = SenseVoiceAPIConfig.load(), urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }
    
    var isConfigured: Bool {
        config != nil
    }
    
    func recognize(wavAudioBase64: String, sampleRate: Int) async throws -> SenseVoiceSpeechResult {
        guard let config else {
            throw SenseVoiceAPIError.missingConfig
        }
        
        let body = SenseVoiceRecognitionRequest(
            model: config.model,
            audio: "data:audio/wav;base64,\(wavAudioBase64)",
            sampleRate: sampleRate,
            language: "auto",
            task: "asr_lid"
        )
        
        var request = URLRequest(url: config.endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = config.apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw SenseVoiceAPIError.invalidResponse
        }
        
        return try JSONDecoder().decode(SenseVoiceSpeechResult.self, from: data)
    }
}
