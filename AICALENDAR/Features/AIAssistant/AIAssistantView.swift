import SwiftUI
import SwiftData

struct AIAssistantView: View {
    @State private var viewModel = AIAssistantViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var theme
    @Query(sort: \CalendarEvent.startDate) private var todayEvents: [CalendarEvent]

    private var todayEventCount: Int {
        todayEvents.filter { $0.startDate.isToday }.count
    }

    private var nextEvent: CalendarEvent? {
        todayEvents.first { $0.startDate.isToday && $0.startDate > Date() }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AxiomColors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status card
                    statusCard
                        .padding(.horizontal, AxiomSpacing.md)
                        .padding(.vertical, AxiomSpacing.sm)

                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: AxiomSpacing.sm) {
                                ForEach(viewModel.messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }

                                if viewModel.isLoading {
                                    HStack {
                                        TypingIndicatorView()
                                        Spacer()
                                    }
                                    .padding(.horizontal, AxiomSpacing.md)
                                }
                            }
                            .padding(.horizontal, AxiomSpacing.md)
                            .padding(.vertical, AxiomSpacing.sm)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let last = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Confirmation card
                    if let action = viewModel.pendingAction {
                        ConfirmationCard(
                            action: action,
                            onApply: {
                                Task { await viewModel.applyPendingAction(modelContext: modelContext) }
                            },
                            onCancel: {
                                viewModel.cancelPendingAction()
                            }
                        )
                    }

                    // Input bar
                    ChatInputBar(
                        text: $viewModel.inputText,
                        isLoading: viewModel.isLoading
                    ) {
                        Task { await viewModel.sendMessage(modelContext: modelContext) }
                    }
                }

                // Voice mode overlay
                if viewModel.isVoiceModeActive {
                    voiceModeOverlay
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleVoiceMode()
                    } label: {
                        Image(systemName: viewModel.isVoiceModeActive ? "waveform.circle.fill" : "waveform.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(viewModel.isVoiceModeActive ? theme.effectiveAccentColor : AxiomColors.textSecondary)
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }

    // MARK: - Voice Mode Overlay

    private var voiceModeOverlay: some View {
        ZStack {
            // Dim background
            AxiomColors.backgroundPrimary.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.stopVoiceMode()
                }

            VStack(spacing: 32) {
                Spacer()

                // Status text
                Text(voiceModeStatusText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AxiomColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Live transcription
                if viewModel.isListeningInVoiceMode && !viewModel.speechService.transcribedText.isEmpty {
                    Text(viewModel.speechService.transcribedText)
                        .font(.system(size: 15))
                        .foregroundStyle(AxiomColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                }

                // Animated orb
                ZStack {
                    // Outer pulse
                    if viewModel.isListeningInVoiceMode || viewModel.ttsService.isSpeaking {
                        Circle()
                            .fill(theme.effectiveAccentColor.opacity(0.15))
                            .frame(width: 160, height: 160)
                            .scaleEffect(viewModel.isListeningInVoiceMode ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isListeningInVoiceMode)

                        Circle()
                            .fill(theme.effectiveAccentColor.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .scaleEffect(viewModel.ttsService.isSpeaking ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.ttsService.isSpeaking)
                    }

                    // Main button
                    Circle()
                        .fill(
                            viewModel.isListeningInVoiceMode
                                ? theme.effectiveAccentColor
                                : (viewModel.ttsService.isSpeaking ? AxiomColors.surface : AxiomColors.surface)
                        )
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: voiceModeIcon)
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(
                                    viewModel.isListeningInVoiceMode
                                        ? .white
                                        : theme.effectiveAccentColor
                                )
                        }
                        .shadow(color: theme.effectiveAccentColor.opacity(0.3), radius: viewModel.isListeningInVoiceMode ? 20 : 5)
                }
                .onTapGesture {
                    handleVoiceOrbTap()
                }

                // Hint text
                Text(voiceModeHint)
                    .font(.system(size: 13))
                    .foregroundStyle(AxiomColors.textSecondary.opacity(0.6))

                Spacer()

                // Close button
                Button {
                    viewModel.stopVoiceMode()
                } label: {
                    Text("End Voice Mode")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AxiomColors.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AxiomColors.surface)
                        .cornerRadius(20)
                }
                .padding(.bottom, 40)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isVoiceModeActive)
        .onAppear {
            // Auto-start listening when entering voice mode
            viewModel.startListening()
        }
    }

    private var voiceModeStatusText: String {
        if viewModel.isLoading { return "Thinking..." }
        if viewModel.ttsService.isSpeaking { return "Axiom is speaking..." }
        if viewModel.isListeningInVoiceMode { return "Listening..." }
        return "Tap to speak"
    }

    private var voiceModeIcon: String {
        if viewModel.isLoading { return "brain" }
        if viewModel.ttsService.isSpeaking { return "waveform" }
        if viewModel.isListeningInVoiceMode { return "mic.fill" }
        return "mic"
    }

    private var voiceModeHint: String {
        if viewModel.isListeningInVoiceMode { return "Tap when done speaking" }
        if viewModel.ttsService.isSpeaking { return "Tap to interrupt" }
        return "Tap the orb to start talking"
    }

    private func handleVoiceOrbTap() {
        if viewModel.ttsService.isSpeaking {
            // Interrupt speech and start listening
            viewModel.ttsService.stop()
            viewModel.startListening()
        } else if viewModel.isListeningInVoiceMode {
            // Stop listening and send
            Task { await viewModel.stopListeningAndSend(modelContext: modelContext) }
        } else {
            // Start listening
            viewModel.startListening()
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("You have \(todayEventCount) events today.")
                    .font(AxiomTypography.caption)
                    .foregroundStyle(AxiomColors.textPrimary)
                if let next = nextEvent {
                    Text("Next: \(next.title) (\(next.startDate.formattedShortTime))")
                        .font(AxiomTypography.micro)
                        .foregroundStyle(AxiomColors.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "sparkles")
                .foregroundStyle(theme.effectiveAccentColor)
        }
        .padding(AxiomSpacing.md)
        .background(AxiomColors.surface)
        .cornerRadius(12)
    }
}

struct TypingIndicatorView: View {
    @State private var dotIndex = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AxiomColors.textSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotIndex == index ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 0.4), value: dotIndex)
            }
        }
        .padding(.horizontal, AxiomSpacing.md)
        .padding(.vertical, AxiomSpacing.sm)
        .background(AxiomColors.surface)
        .cornerRadius(16)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(400))
                dotIndex = (dotIndex + 1) % 3
            }
        }
    }
}
