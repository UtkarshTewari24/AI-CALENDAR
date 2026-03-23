import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var viewModel = TimelineViewModel()
    @Query(sort: \CalendarEvent.startDate) private var allEvents: [CalendarEvent]

    var body: some View {
        NavigationStack {
            ZStack {
                AxiomColors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Text(viewModel.selectedDate.formattedDate)
                            .font(AxiomTypography.headline)
                            .foregroundStyle(AxiomColors.textPrimary)

                        Spacer()

                        // Day/Week toggle
                        Picker("View", selection: Binding(
                            get: { viewModel.displayMode },
                            set: { _ in viewModel.toggleDisplayMode() }
                        )) {
                            Text("Day").tag(TimelineDisplayMode.day)
                            Text("Week").tag(TimelineDisplayMode.week)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)

                        Button {
                            viewModel.showingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AxiomColors.accent)
                        }
                        .padding(.leading, AxiomSpacing.sm)
                    }
                    .padding(.horizontal, AxiomSpacing.md)
                    .padding(.vertical, AxiomSpacing.sm)

                    // Timeline content
                    switch viewModel.displayMode {
                    case .day:
                        DayTimelineView(
                            events: viewModel.eventsForDate(viewModel.selectedDate, from: allEvents),
                            hourHeight: theme.hourHeight,
                            onEventTap: { event in
                                viewModel.selectedEvent = event
                            },
                            onEventReschedule: { event, minutes in
                                viewModel.rescheduleEvent(event, toStartMinutes: minutes, hourHeight: theme.hourHeight)
                            }
                        )

                    case .week:
                        WeekGridView(
                            events: viewModel.eventsForWeek(from: allEvents),
                            selectedDate: viewModel.selectedDate,
                            hourHeight: theme.hourHeight * 0.6,
                            onDateSelect: { date in
                                viewModel.selectDate(date)
                            },
                            onEventTap: { event in
                                viewModel.selectedEvent = event
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddSheet) {
            AddEventView(prefilledDate: viewModel.selectedDate)
        }
        .sheet(item: $viewModel.selectedEvent) { event in
            EventDetailView(event: event)
                .presentationDetents([.fraction(0.6)])
        }
    }
}
