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
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }

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
                .foregroundStyle(theme.accentColor)
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
