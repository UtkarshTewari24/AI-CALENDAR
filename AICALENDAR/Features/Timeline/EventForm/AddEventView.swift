import SwiftUI
import SwiftData

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var theme

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var eventType: EventType = .personal
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var selectedIcon: String?

    var prefilledDate: Date?

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Title", text: $title)

                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)
                }

                Section("Type") {
                    EventTypePicker(selectedType: $eventType)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(IconSuggestionService.commonIcons, id: \.self) { icon in
                            Button {
                                if selectedIcon == icon {
                                    selectedIcon = nil
                                } else {
                                    selectedIcon = icon
                                }
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        selectedIcon == icon
                                            ? theme.effectiveAccentColor.opacity(0.2)
                                            : Color.clear
                                    )
                                    .foregroundStyle(
                                        selectedIcon == icon
                                            ? theme.effectiveAccentColor
                                            : AxiomColors.textSecondary
                                    )
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selectedIcon == icon
                                                    ? theme.effectiveAccentColor
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Options") {
                    Toggle("Recurring", isOn: $isRecurring)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let date = prefilledDate {
                    startDate = date
                    endDate = date.addingTimeInterval(3600)
                }
            }
        }
    }

    private func saveEvent() {
        let event = CalendarEvent(
            title: title.trimmingCharacters(in: .whitespaces),
            startDate: startDate,
            endDate: endDate,
            type: eventType,
            notes: notes,
            isRecurring: isRecurring,
            iconName: selectedIcon
        )
        modelContext.insert(event)
    }
}
