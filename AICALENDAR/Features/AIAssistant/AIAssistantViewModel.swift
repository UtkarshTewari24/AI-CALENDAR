import SwiftUI
import SwiftData

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
    var pendingActions: [PendingAction]?
    let timestamp = Date()

    enum ChatRole {
        case user
        case assistant
        case system
    }
}

struct PendingAction: Identifiable {
    let id = UUID()
    let description: String
    let toolCalls: [OpenAIToolCall]
}

@Observable
final class AIAssistantViewModel {
    var messages: [ChatMessage] = []
    var inputText = ""
    var isLoading = false
    var pendingAction: PendingAction?
    var errorMessage: String?

    // Voice mode
    var isVoiceModeActive = false
    var isListeningInVoiceMode = false
    let ttsService = TextToSpeechService()
    let speechService = SpeechRecognitionService()

    private var conversationHistory: [OpenAIMessage] = []

    init() {
        let systemMessage = """
        You are Axiom, a personal AI schedule assistant. You have access to the user's calendar and task list. \
        You can add, remove, reschedule, and swap events. You can also create tasks. \
        Today is \(Date().formattedDate). Current time is \(Date().formattedTime).

        Rules:
        - Be concise. Keep responses to 1-2 short sentences.
        - NEVER use markdown formatting (no **, *, #, `, etc). Write plain text only.
        - When making multiple changes, batch ALL tool calls into a single response. Do NOT make one change at a time.
        - Before making changes, give a brief plain-text summary like "I'll add your morning workout and move lunch to 1pm." — no bullet lists, no time formatting with bold/italic.
        - If the user asks to set up or rearrange multiple things, do them all at once in one batch of tool calls.
        - Use the available tools to read and modify the calendar.
        """
        conversationHistory.append(.system(systemMessage))
    }

    func sendMessage(modelContext: ModelContext) async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        conversationHistory.append(.user(text))

        do {
            try await processConversation(modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            messages.append(ChatMessage(role: .system, content: "Error: \(error.localizedDescription)"))
        }

        isLoading = false

        // Auto-speak in voice mode
        if isVoiceModeActive {
            speakLastResponse()
        }
    }

    func applyPendingAction(modelContext: ModelContext) async {
        guard let action = pendingAction else { return }
        isLoading = true

        // Execute the tool calls
        for toolCall in action.toolCalls {
            let result = FunctionExecutor.execute(
                functionName: toolCall.function.name,
                arguments: toolCall.function.arguments,
                modelContext: modelContext
            )

            conversationHistory.append(.assistantWithToolCalls([toolCall]))
            conversationHistory.append(.toolResult(callId: toolCall.id, content: result))
        }

        pendingAction = nil

        do {
            let response = try await OpenAIService.sendChatCompletion(
                messages: conversationHistory,
                tools: CalendarFunctions.allTools
            )

            if let content = response.firstMessageContent {
                conversationHistory.append(.assistant(content))
                messages.append(ChatMessage(role: .assistant, content: content))
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func cancelPendingAction() {
        pendingAction = nil
        messages.append(ChatMessage(role: .system, content: "Action cancelled."))
    }

    // MARK: - Voice Mode

    func toggleVoiceMode() {
        isVoiceModeActive.toggle()
        if !isVoiceModeActive {
            stopVoiceMode()
        }
    }

    func startListening() {
        ttsService.stop()
        speechService.transcribedText = ""
        isListeningInVoiceMode = true
        try? speechService.startRecording()
    }

    func stopListeningAndSend(modelContext: ModelContext) async {
        speechService.stopRecording()
        isListeningInVoiceMode = false

        let text = speechService.transcribedText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        inputText = text
        await sendMessage(modelContext: modelContext)
    }

    func speakLastResponse() {
        guard let lastAssistant = messages.last(where: { $0.role == .assistant }) else { return }
        ttsService.speak(lastAssistant.content) { [weak self] in
            // Auto-listen after speaking in voice mode
            guard let self, self.isVoiceModeActive else { return }
            self.startListening()
        }
    }

    func stopVoiceMode() {
        ttsService.stop()
        speechService.stopRecording()
        isListeningInVoiceMode = false
        isVoiceModeActive = false
    }

    private func processConversation(modelContext: ModelContext) async throws {
        let response = try await OpenAIService.sendChatCompletion(
            messages: conversationHistory,
            tools: CalendarFunctions.allTools
        )

        // Check if we have tool calls
        if let toolCalls = response.firstToolCalls, !toolCalls.isEmpty {
            // Check if any tool call is a write operation (needs confirmation)
            let writeOps = ["add_event", "update_event", "delete_event", "swap_events", "create_task"]
            let hasWrite = toolCalls.contains { writeOps.contains($0.function.name) }

            if hasWrite {
                // Build description and present for confirmation
                let descriptions = toolCalls.map { describeToolCall($0) }.joined(separator: "\n")
                let assistantText = response.firstMessageContent ?? "I'd like to make the following changes:"
                messages.append(ChatMessage(role: .assistant, content: assistantText))

                pendingAction = PendingAction(
                    description: descriptions,
                    toolCalls: toolCalls
                )
            } else {
                // Read-only operations, execute immediately
                for toolCall in toolCalls {
                    let result = FunctionExecutor.execute(
                        functionName: toolCall.function.name,
                        arguments: toolCall.function.arguments,
                        modelContext: modelContext
                    )
                    conversationHistory.append(.assistantWithToolCalls([toolCall]))
                    conversationHistory.append(.toolResult(callId: toolCall.id, content: result))
                }

                // Continue conversation with tool results
                try await processConversation(modelContext: modelContext)
            }
        } else if let content = response.firstMessageContent {
            conversationHistory.append(.assistant(content))
            messages.append(ChatMessage(role: .assistant, content: content))
        }
    }

    private func describeToolCall(_ toolCall: OpenAIToolCall) -> String {
        let name = toolCall.function.name
        guard let data = toolCall.function.arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return name
        }

        switch name {
        case "add_event":
            let title = args["title"] as? String ?? "event"
            let start = args["startTime"] as? String ?? ""
            let end = args["endTime"] as? String ?? ""
            return "Add '\(title)' from \(start) to \(end)"
        case "delete_event":
            return "Remove an event"
        case "update_event":
            return "Update an event"
        case "swap_events":
            return "Swap two events' times"
        case "create_task":
            let title = args["title"] as? String ?? "task"
            return "Create task: '\(title)'"
        default:
            return name
        }
    }
}
