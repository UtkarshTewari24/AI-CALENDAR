import SwiftUI
import SwiftData

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var eventType: EventType = .personal
    @State private var notes = ""
    @State private var isRecurring = false

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
            isRecurring: isRecurring
        )
        modelContext.insert(event)
    }
}
