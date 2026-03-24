import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - OpenAI Message Types

struct OpenAIMessage: Codable {
    let role: String
    var content: OpenAIContent?
    var toolCalls: [OpenAIToolCall]?
    var toolCallId: String?
    var name: String?

    enum CodingKeys: String, CodingKey {
        case role, content, name
        case toolCalls = "tool_calls"
        case toolCallId = "tool_call_id"
    }

    static func system(_ text: String) -> OpenAIMessage {
        OpenAIMessage(role: "system", content: .text(text))
    }

    static func user(_ text: String) -> OpenAIMessage {
        OpenAIMessage(role: "user", content: .text(text))
    }

    static func userWithImage(text: String, imageBase64: String) -> OpenAIMessage {
        OpenAIMessage(role: "user", content: .multipart([
            .init(type: "text", text: text, imageUrl: nil),
            .init(type: "image_url", text: nil, imageUrl: .init(url: "data:image/jpeg;base64,\(imageBase64)"))
        ]))
    }

    static func assistant(_ text: String) -> OpenAIMessage {
        OpenAIMessage(role: "assistant", content: .text(text))
    }

    static func assistantWithToolCalls(_ toolCalls: [OpenAIToolCall]) -> OpenAIMessage {
        OpenAIMessage(role: "assistant", content: nil, toolCalls: toolCalls)
    }

    static func toolResult(callId: String, content: String) -> OpenAIMessage {
        OpenAIMessage(role: "tool", content: .text(content), toolCallId: callId)
    }
}

enum OpenAIContent: Codable {
    case text(String)
    case multipart([ContentPart])

    struct ContentPart: Codable {
        let type: String
        var text: String?
        var imageUrl: ImageURL?

        enum CodingKeys: String, CodingKey {
            case type, text
            case imageUrl = "image_url"
        }

        struct ImageURL: Codable {
            let url: String
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else if let parts = try? container.decode([ContentPart].self) {
            self = .multipart(parts)
        } else {
            self = .text("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let string):
            try container.encode(string)
        case .multipart(let parts):
            try container.encode(parts)
        }
    }

    var textValue: String {
        switch self {
        case .text(let string): return string
        case .multipart(let parts): return parts.compactMap(\.text).joined()
        }
    }
}

struct OpenAIToolCall: Codable, Identifiable {
    let id: String
    let type: String
    let function: FunctionCall

    struct FunctionCall: Codable {
        let name: String
        let arguments: String
    }
}

struct OpenAITool: Codable {
    let type: String
    let function: FunctionDefinition

    struct FunctionDefinition: Codable {
        let name: String
        let description: String
        let parameters: JSONSchema
    }

    static func function(name: String, description: String, parameters: JSONSchema) -> OpenAITool {
        OpenAITool(type: "function", function: FunctionDefinition(name: name, description: description, parameters: parameters))
    }
}

final class JSONSchema: Codable {
    let type: String
    var properties: [String: JSONSchema]?
    var required: [String]?
    var items: JSONSchema?
    var description: String?
    var enumValues: [String]?

    enum CodingKeys: String, CodingKey {
        case type, properties, required, items, description
        case enumValues = "enum"
    }

    init(type: String, properties: [String: JSONSchema]? = nil, required: [String]? = nil, items: JSONSchema? = nil, description: String? = nil, enumValues: [String]? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
        self.items = items
        self.description = description
        self.enumValues = enumValues
    }

    static func object(properties: [String: JSONSchema], required: [String]? = nil) -> JSONSchema {
        JSONSchema(type: "object", properties: properties, required: required)
    }

    static func string(description: String? = nil, enumValues: [String]? = nil) -> JSONSchema {
        JSONSchema(type: "string", description: description, enumValues: enumValues)
    }

    static func number(description: String? = nil) -> JSONSchema {
        JSONSchema(type: "number", description: description)
    }

    static func integer(description: String? = nil) -> JSONSchema {
        JSONSchema(type: "integer", description: description)
    }

    static func boolean(description: String? = nil) -> JSONSchema {
        JSONSchema(type: "boolean", description: description)
    }

    static func array(items: JSONSchema, description: String? = nil) -> JSONSchema {
        JSONSchema(type: "array", items: items, description: description)
    }
}

// MARK: - OpenAI Response

struct OpenAIResponse: Codable {
    let id: String?
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Codable {
        let message: OpenAIMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    struct Usage: Codable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }

    var firstMessageContent: String? {
        choices.first?.message.content?.textValue
    }

    var firstToolCalls: [OpenAIToolCall]? {
        choices.first?.message.toolCalls
    }

    var finishReason: String? {
        choices.first?.finishReason
    }
}

// MARK: - OpenAI Service

enum OpenAIServiceError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case requestFailed(String)
    case decodingFailed(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key configured. Please restart the app or add your API key in Settings."
        case .invalidURL: return "Invalid API URL."
        case .requestFailed(let msg): return "Request failed: \(msg)"
        case .decodingFailed(let msg): return "Failed to decode response: \(msg)"
        case .emptyResponse: return "Empty response from API."
        }
    }
}

enum OpenAIService {

    private static let baseURL = "https://api.groq.com/openai/v1/chat/completions"

    static func sendChatCompletion(
        messages: [OpenAIMessage],
        tools: [OpenAITool]? = nil,
        model: String = "openai/gpt-oss-120b",
        temperature: Double = 0.7,
        responseFormat: [String: String]? = nil,
        systemPrompt: String? = nil
    ) async throws -> OpenAIResponse {
        guard let apiKey = KeychainService.openAIAPIKey, !apiKey.isEmpty else {
            throw OpenAIServiceError.noAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw OpenAIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build messages array, prepending system prompt if provided separately
        var allMessages = messages
        if let systemPrompt {
            allMessages.insert(.system(systemPrompt), at: 0)
        }

        var body: [String: Any] = [
            "model": model,
            "temperature": temperature
        ]

        // Encode messages
        let encoder = JSONEncoder()
        let messagesData = try encoder.encode(allMessages)
        let messagesJSON = try JSONSerialization.jsonObject(with: messagesData)
        body["messages"] = messagesJSON

        // Encode tools if provided
        if let tools {
            let toolsData = try encoder.encode(tools)
            let toolsJSON = try JSONSerialization.jsonObject(with: toolsData)
            body["tools"] = toolsJSON
        }

        // Response format
        if let responseFormat {
            body["response_format"] = responseFormat
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.requestFailed("Invalid response type")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIServiceError.requestFailed("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(OpenAIResponse.self, from: data)
        } catch {
            throw OpenAIServiceError.decodingFailed(error.localizedDescription)
        }
    }

    static func testConnection() async -> Bool {
        do {
            let messages = [OpenAIMessage.user("Say 'ok' and nothing else.")]
            let response = try await sendChatCompletion(messages: messages, temperature: 0)
            return response.firstMessageContent != nil
        } catch {
            return false
        }
    }
}
