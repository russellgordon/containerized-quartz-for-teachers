import Foundation

/// One turn's worth of conversation, in the shape llama.cpp's OpenAI-compatible
/// endpoint expects.
struct AssistMessage: Codable, Equatable, Sendable {

    // MARK: - Stored properties

    let role: String
    let content: String?
    let toolCalls: [AssistToolCall]?
    let toolCallID: String?
    let name: String?

    // MARK: - Initializer

    init(role: String,
         content: String?,
         toolCalls: [AssistToolCall]? = nil,
         toolCallID: String? = nil,
         name: String? = nil) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case toolCalls = "tool_calls"
        case toolCallID = "tool_call_id"
        case name
    }

    // MARK: - Functions

    static func system(_ text: String) -> AssistMessage {
        return AssistMessage(role: "system", content: text)
    }

    static func user(_ text: String) -> AssistMessage {
        return AssistMessage(role: "user", content: text)
    }

    static func toolResult(callID: String, name: String, text: String) -> AssistMessage {
        return AssistMessage(role: "tool", content: text, toolCallID: callID, name: name)
    }
}

/// A tool the model asked to run.
struct AssistToolCall: Codable, Equatable, Sendable, Identifiable {

    // MARK: - Types

    struct Function: Codable, Equatable, Sendable {
        let name: String
        /// JSON, as a string — that is how the endpoint sends it.
        let arguments: String
    }

    // MARK: - Stored properties

    let id: String
    let type: String
    let function: Function

    // MARK: - Computed properties

    /// The arguments, decoded. An empty dictionary when the model sent
    /// something that is not an object, which it occasionally does.
    var argumentValues: [String: Any] {
        guard let data = function.arguments.data(using: .utf8) else {
            return [:]
        }
        let parsed: Any? = try? JSONSerialization.jsonObject(with: data)
        return (parsed as? [String: Any]) ?? [:]
    }
}

/// Talks to the local `llama-server`.
///
/// Deliberately the OpenAI shape rather than anything bespoke: it is what
/// llama.cpp speaks, what the Windows suite measures against, and what a
/// teacher's own assistant would speak if they ever pointed one at the MCP
/// server instead.
struct AssistModelClient: Sendable {

    // MARK: - Stored properties

    let baseURL: URL

    // MARK: - Functions

    /// Ask the model for its next move.
    ///
    /// `temperature` is 0: this is a router, and a router that answers
    /// differently to the same request twice is a router a teacher cannot
    /// learn to trust.
    func respond(messages: [AssistMessage],
                 tools: [AssistToolDefinition]) async throws -> AssistMessage {
        var body: [String: Any] = [
            "messages": try encodeMessages(messages),
            "temperature": 0,
            "stream": false,
        ]
        if !tools.isEmpty {
            body["tools"] = try encodeTools(tools)
            body["tool_choice"] = "auto"
        }

        var request: URLRequest = URLRequest(url: baseURL.appendingPathComponent("v1/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        // Generous: a cold prefix read on the large model is about twelve
        // seconds, and a slow disk can add to that on the very first call.
        request.timeoutInterval = 180

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code: Int = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AssistModelError.badResponse(status: code, body: String(data: data, encoding: .utf8) ?? "")
        }

        return try decodeReply(from: data)
    }

    // MARK: - Encoding

    private func encodeMessages(_ messages: [AssistMessage]) throws -> [[String: Any]] {
        var encoded: [[String: Any]] = []
        for message in messages {
            var item: [String: Any] = ["role": message.role]
            item["content"] = message.content ?? ""
            if let toolCallID = message.toolCallID {
                item["tool_call_id"] = toolCallID
            }
            if let name = message.name {
                item["name"] = name
            }
            if let calls = message.toolCalls {
                var encodedCalls: [[String: Any]] = []
                for call in calls {
                    encodedCalls.append([
                        "id": call.id,
                        "type": call.type,
                        "function": ["name": call.function.name, "arguments": call.function.arguments],
                    ])
                }
                item["tool_calls"] = encodedCalls
            }
            encoded.append(item)
        }
        return encoded
    }

    private func encodeTools(_ tools: [AssistToolDefinition]) throws -> [[String: Any]] {
        var encoded: [[String: Any]] = []
        for tool in tools {
            encoded.append([
                "type": "function",
                "function": [
                    "name": tool.name,
                    "description": tool.description,
                    "parameters": tool.parametersJSON,
                ],
            ])
        }
        return encoded
    }

    // MARK: - Decoding

    private func decodeReply(from data: Data) throws -> AssistMessage {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = root["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any] else {
            throw AssistModelError.unreadableReply
        }

        let content: String? = message["content"] as? String
        var calls: [AssistToolCall] = []
        if let rawCalls = message["tool_calls"] as? [[String: Any]] {
            for raw in rawCalls {
                guard let function = raw["function"] as? [String: Any],
                      let name = function["name"] as? String else {
                    continue
                }
                // Some builds send arguments as an object rather than the
                // string the schema promises; both are accepted because a
                // dropped tool call reads to a teacher as the assistant
                // ignoring them.
                var arguments: String = ""
                if let text = function["arguments"] as? String {
                    arguments = text
                } else if let object = function["arguments"] {
                    if let encoded = try? JSONSerialization.data(withJSONObject: object),
                       let text = String(data: encoded, encoding: .utf8) {
                        arguments = text
                    }
                }
                let id: String = (raw["id"] as? String) ?? UUID().uuidString
                calls.append(AssistToolCall(
                    id: id,
                    type: "function",
                    function: AssistToolCall.Function(name: name, arguments: arguments)
                ))
            }
        }

        return AssistMessage(
            role: "assistant",
            content: content,
            toolCalls: calls.isEmpty ? nil : calls
        )
    }
}

/// What can go wrong talking to the engine.
enum AssistModelError: LocalizedError, Equatable {
    case badResponse(status: Int, body: String)
    case unreadableReply

    var errorDescription: String? {
        switch self {
        case .badResponse(let status, _):
            return "The assistant's engine answered with an error (\(status))."
        case .unreadableReply:
            return "The assistant's engine sent a reply Plantoir could not read."
        }
    }
}
