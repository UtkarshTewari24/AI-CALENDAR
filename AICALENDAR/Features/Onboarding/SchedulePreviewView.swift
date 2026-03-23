import SwiftUI
import SwiftData

struct SchedulePreviewView: View {
    @Bindable var coordinator: OnboardingCoordinator
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var editingEvent: CalendarEvent?

    private let dayOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        ZStack {
            AxiomColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: AxiomSpacing.xs) {
                    Text("Your Schedule")
                        .font(AxiomTypography.title1)
                        .foregroundStyle(AxiomColors.textPrimary)
                    Text("\(coordinator.generatedEvents.count) events across 7 days")
                        .font(AxiomTypography.caption)
                        .foregroundStyle(AxiomColors.textSecondary)
                }
                .padding(.top, AxiomSpacing.lg)

                // Events grouped by day
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AxiomSpacing.lg) {
                        ForEach(groupedEvents, id: \.0) { day, events in
                            Section {
                                ForEach(events, id: \.id) { event in
                                    PreviewEventRow(event: event)
                                        .onTapGesture {
                                            editingEvent = event
                                        }
                                }
                            } header: {
                                Text(day)
                                    .font(AxiomTypography.headline)
                                    .foregroundStyle(AxiomColors.accent)
                                    .padding(.top, AxiomSpacing.sm)
                            }
                        }
                    }
                    .padding(AxiomSpacing.lg)
                }

                // Bottom buttons
                VStack(spacing: AxiomSpacing.sm) {
                    if coordinator.canRegenerate {
                        Button("Regenerate (\(coordinator.maxRegenerations - coordinator.regenerationCount) left)") {
                            Task { await coordinator.regenerateSchedule() }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(AxiomColors.surface)
                        .foregroundStyle(AxiomColors.textPrimary)
                        .font(AxiomTypography.caption)
                        .cornerRadius(12)
                    }

                    Button("This looks good — Let's go") {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        coordinator.confirmSchedule(modelContext: modelContext, appState: appState)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AxiomColors.accent)
                    .foregroundStyle(.white)
                    .font(AxiomTypography.headline)
                    .cornerRadius(12)
                }
                .padding(.horizontal, AxiomSpacing.lg)
                .padding(.bottom, AxiomSpacing.lg)
            }
        }
        .sheet(item: $editingEvent) { event in
            PreviewEventEditSheet(event: event) {
                editingEvent = nil
            } onDelete: {
                coordinator.generatedEvents.removeAll { $0.id == event.id }
                editingEvent = nil
            }
        }
    }

    private var groupedEvents: [(String, [CalendarEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: coordinator.generatedEvents) { event -> String in
            let weekday = calendar.component(.weekday, from: event.startDate)
            // Convert Sunday=1...Saturday=7 to Mon-Sun display
            let dayIndex = (weekday + 5) % 7 // Mon=0, Tue=1, ... Sun=6
            return dayOrder[dayIndex]
        }

        return dayOrder.compactMap { day in
            guard let events = grouped[day], !events.isEmpty else { return nil }
            let sorted = events.sorted { $0.startDate < $1.startDate }
            return (day, sorted)
        }
    }
}

// MARK: - Preview Event Row

private struct PreviewEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: AxiomSpacing.md) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AxiomColors.color(for: event.type))
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(AxiomTypography.body)
                    .foregroundStyle(AxiomColors.textPrimary)
                Text(event.startDate.formatTimeRange(to: event.endDate))
                    .font(AxiomTypography.mono)
                    .foregroundStyle(AxiomColors.textSecondary)
            }

            Spacer()

            Text(event.type.displayName)
                .font(AxiomTypography.micro)
                .padding(.horizontal, AxiomSpacing.sm)
                .padding(.vertical, AxiomSpacing.xs)
                .background(AxiomColors.color(for: event.type).opacity(0.2))
                .foregroundStyle(AxiomColors.color(for: event.type))
                .cornerRadius(8)
        }
        .padding(AxiomSpacing.md)
        .background(AxiomColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Edit Sheet

private struct PreviewEventEditSheet: View {
    let event: CalendarEvent
    let onDismiss: () -> Void
    let onDelete: () -> Void

    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date

    init(event: CalendarEvent, onDismiss: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.event = event
        self.onDismiss = onDismiss
        self.onDelete = onDelete
        self._title = State(initialValue: event.title)
        self._startDate = State(initialValue: event.startDate)
        self._endDate = State(initialValue: event.endDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)
                }

                Section {
                    Button("Delete Event", role: .destructive) {
                        onDelete()
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        event.title = title
                        event.startDate = startDate
                        event.endDate = endDate
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}


