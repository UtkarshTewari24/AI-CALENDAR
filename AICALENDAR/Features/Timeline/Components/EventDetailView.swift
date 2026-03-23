import SwiftUI
import SwiftData

struct EventDetailView: View {
    let event: CalendarEvent
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var editTitle: String = ""
    @State private var editStartDate: Date = Date()
    @State private var editEndDate: Date = Date()
    @State private var editType: EventType = .personal
    @State private var editNotes: String = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AxiomSpacing.md) {
                // Type badge
                HStack {
                    Text(event.type.displayName)
                        .font(AxiomTypography.micro)
                        .padding(.horizontal, AxiomSpacing.sm)
                        .padding(.vertical, AxiomSpacing.xs)
                        .background(AxiomColors.color(for: event.type).opacity(0.2))
                        .foregroundStyle(AxiomColors.color(for: event.type))
                        .clipShape(Capsule())
                    Spacer()
                }

                if isEditing {
                    editForm
                } else {
                    displayView
                }

                Spacer()
            }
            .padding(AxiomSpacing.lg)
            .navigationTitle(isEditing ? "Edit Event" : event.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("Save") {
                            saveEdits()
                            isEditing = false
                        }
                    } else {
                        Menu {
                            Button("Edit") {
                                prepareEdit()
                                isEditing = true
                            }
                            Button("Delete", role: .destructive) {
                                showDeleteConfirmation = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog("Delete Event", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(event)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this event?")
            }
        }
    }

    private var displayView: some View {
        VStack(alignment: .leading, spacing: AxiomSpacing.md) {
            Label(event.startDate.formatTimeRange(to: event.endDate), systemImage: "clock")
                .font(AxiomTypography.mono)
                .foregroundStyle(AxiomColors.textSecondary)

            Label(event.startDate.formattedDate, systemImage: "calendar")
                .font(AxiomTypography.caption)
                .foregroundStyle(AxiomColors.textSecondary)

            if !event.notes.isEmpty {
                Text(event.notes)
                    .font(AxiomTypography.body)
                    .foregroundStyle(AxiomColors.textPrimary)
                    .padding(.top, AxiomSpacing.sm)
            }

            if event.isRecurring {
                Label("Recurring event", systemImage: "repeat")
                    .font(AxiomTypography.caption)
                    .foregroundStyle(AxiomColors.textSecondary)
            }
        }
    }

    private var editForm: some View {
        VStack(spacing: AxiomSpacing.md) {
            TextField("Title", text: $editTitle)
                .textFieldStyle(.roundedBorder)
            DatePicker("Start", selection: $editStartDate)
            DatePicker("End", selection: $editEndDate)
            EventTypePicker(selectedType: $editType)
            TextField("Notes", text: $editNotes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    private func prepareEdit() {
        editTitle = event.title
        editStartDate = event.startDate
        editEndDate = event.endDate
        editType = event.type
        editNotes = event.notes
    }

    private func saveEdits() {
        event.title = editTitle
        event.startDate = editStartDate
        event.endDate = editEndDate
        event.type = editType
        event.notes = editNotes
    }
}
