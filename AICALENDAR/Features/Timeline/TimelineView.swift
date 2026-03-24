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
                    // Header with month/year and add button
                    headerView

                    // Week day selector
                    weekDaySelector

                    // Day/Week toggle
                    Picker("View", selection: Binding(
                        get: { viewModel.displayMode },
                        set: { _ in viewModel.toggleDisplayMode() }
                    )) {
                        Text("Day").tag(TimelineDisplayMode.day)
                        Text("Week").tag(TimelineDisplayMode.week)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AxiomSpacing.md)
                    .padding(.bottom, AxiomSpacing.sm)

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
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $viewModel.showingAddSheet) {
            AddEventView(prefilledDate: viewModel.selectedDate)
        }
        .sheet(item: $viewModel.selectedEvent) { event in
            EventDetailView(event: event)
                .presentationDetents([.fraction(0.6)])
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Month in white, year in accent
            HStack(spacing: 6) {
                Text(monthString)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AxiomColors.textPrimary)

                Text(yearString + " ›")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(theme.effectiveAccentColor)
            }

            Spacer()

            Button {
                viewModel.showingAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(theme.effectiveAccentColor)
            }
        }
        .padding(.horizontal, AxiomSpacing.md)
        .padding(.top, AxiomSpacing.sm)
        .padding(.bottom, AxiomSpacing.xs)
    }

    // MARK: - Week Day Selector

    private var weekDaySelector: some View {
        let weekDays = viewModel.selectedDate.daysOfWeek()

        return HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                let isSelected = day.isSameDay(as: viewModel.selectedDate)
                let isToday = day.isToday

                VStack(spacing: 4) {
                    Text(day.dayOfWeekShort.prefix(3).uppercased())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isSelected ? theme.effectiveAccentColor : AxiomColors.textSecondary)

                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(theme.effectiveAccentColor)
                                .frame(width: 32, height: 32)
                        } else if isToday {
                            Circle()
                                .stroke(theme.effectiveAccentColor, lineWidth: 1.5)
                                .frame(width: 32, height: 32)
                        }

                        Text(day.dayNumber)
                            .font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular))
                            .foregroundStyle(isSelected ? .white : (isToday ? theme.effectiveAccentColor : AxiomColors.textPrimary))
                    }
                    .frame(width: 32, height: 32)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectDate(day)
                }
            }
        }
        .padding(.horizontal, AxiomSpacing.sm)
        .padding(.vertical, AxiomSpacing.sm)
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: viewModel.selectedDate)
    }

    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: viewModel.selectedDate)
    }
}
