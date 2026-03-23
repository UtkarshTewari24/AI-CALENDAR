import SwiftUI

struct SurveyView: View {
    @Bindable var coordinator: OnboardingCoordinator
    @State private var currentPage = 0
    private let totalPages = 5

    var body: some View {
        ZStack {
            AxiomColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(currentPage + 1), total: Double(totalPages))
                    .tint(AxiomColors.accent)
                    .padding(.horizontal, AxiomSpacing.lg)
                    .padding(.top, AxiomSpacing.md)

                Text("Step \(currentPage + 1) of \(totalPages)")
                    .font(AxiomTypography.micro)
                    .foregroundStyle(AxiomColors.textSecondary)
                    .padding(.top, AxiomSpacing.sm)

                // Survey pages - no swipe, button-driven only
                Group {
                    switch currentPage {
                    case 0:
                        DailyRhythmPage(survey: $coordinator.surveyResponse)
                    case 1:
                        FitnessPage(survey: $coordinator.surveyResponse)
                    case 2:
                        WorkStudyPage(survey: $coordinator.surveyResponse)
                    case 3:
                        RoutinesPage(survey: $coordinator.surveyResponse)
                    default:
                        PrioritiesPage(survey: $coordinator.surveyResponse)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentPage)

                // Navigation buttons
                HStack(spacing: AxiomSpacing.md) {
                    if currentPage > 0 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                currentPage -= 1
                            }
                        } label: {
                            Text("Back")
                                .font(AxiomTypography.headline)
                                .foregroundStyle(AxiomColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(AxiomColors.surface)
                                .cornerRadius(12)
                        }
                    }

                    Button {
                        if currentPage == totalPages - 1 {
                            coordinator.advanceToGeneration()
                            Task { await coordinator.generateSchedule() }
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                currentPage += 1
                            }
                        }
                    } label: {
                        Text(currentPage == totalPages - 1 ? "Generate Schedule" : "Next")
                            .font(AxiomTypography.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AxiomColors.accent)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, AxiomSpacing.lg)
                .padding(.bottom, AxiomSpacing.lg)
            }
        }
    }
}

// MARK: - Section A: Daily Rhythm

private struct DailyRhythmPage: View {
    @Binding var survey: SurveyResponse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AxiomSpacing.lg) {
                SurveyHeader(title: "Daily Rhythm", subtitle: "Tell us about your typical day.")

                SurveyQuestion(title: "What time do you wake up?") {
                    HStack {
                        Picker("Hour", selection: $survey.wakeUpHour) {
                            ForEach(4...12, id: \.self) { hour in
                                Text("\(hour):00 AM").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }

                SurveyQuestion(title: "What time do you go to sleep?") {
                    Picker("Hour", selection: $survey.sleepHour) {
                        ForEach(20...27, id: \.self) { hour in
                            let displayHour = hour > 24 ? hour - 24 : hour
                            let period = hour >= 24 ? "AM" : "PM"
                            let display12 = displayHour > 12 ? displayHour - 12 : displayHour
                            Text("\(display12):00 \(period)").tag(hour > 24 ? hour - 24 : hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }

                SurveyQuestion(title: "Are you a morning person, night person, or in between?") {
                    ChipSelector(
                        options: Chronotype.allCases,
                        selected: $survey.chronotype
                    )
                }

                SurveyQuestion(title: "Hours of work/study on an average weekday?") {
                    VStack {
                        Text("\(Int(survey.workStudyHours)) hours")
                            .font(AxiomTypography.title2)
                            .foregroundStyle(AxiomColors.textPrimary)
                        Slider(value: $survey.workStudyHours, in: 0...14, step: 1)
                            .tint(AxiomColors.accent)
                    }
                }
            }
            .padding(AxiomSpacing.lg)
        }
    }
}

// MARK: - Section B: Fitness

private struct FitnessPage: View {
    @Binding var survey: SurveyResponse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AxiomSpacing.lg) {
                SurveyHeader(title: "Fitness & Health", subtitle: "Let's understand your physical routines.")

                SurveyQuestion(title: "Do you currently exercise?") {
                    ChipSelector(
                        options: ExerciseFrequency.allCases,
                        selected: $survey.doesExercise
                    )
                }

                if survey.doesExercise != .no {
                    SurveyQuestion(title: "What types of exercise?") {
                        MultiChipSelector(
                            options: ExerciseType.allCases,
                            selected: $survey.exerciseTypes
                        )
                    }
                }

                SurveyQuestion(title: "Do you follow any dietary structure?") {
                    MultiChipSelector(
                        options: DietaryOption.allCases,
                        selected: $survey.dietaryStructure
                    )
                }

                if survey.dietaryStructure.contains(.specificMealTimes) {
                    SurveyQuestion(title: "When do you eat?") {
                        VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
                            MealTimePicker(label: "Breakfast", hour: $survey.mealTimes.breakfastHour, minute: $survey.mealTimes.breakfastMinute)
                            MealTimePicker(label: "Lunch", hour: $survey.mealTimes.lunchHour, minute: $survey.mealTimes.lunchMinute)
                            MealTimePicker(label: "Dinner", hour: $survey.mealTimes.dinnerHour, minute: $survey.mealTimes.dinnerMinute)
                        }
                    }
                }
            }
            .padding(AxiomSpacing.lg)
        }
    }
}

// MARK: - Section C: Work / Study

private struct WorkStudyPage: View {
    @Binding var survey: SurveyResponse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AxiomSpacing.lg) {
                SurveyHeader(title: "Work & Study", subtitle: "Your professional or academic focus.")

                SurveyQuestion(title: "Describe your primary occupation or focus area.") {
                    TextField("e.g. CS student, Freelance designer", text: $survey.occupation)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(AxiomColors.surface)
                        .cornerRadius(12)
                        .foregroundStyle(AxiomColors.textPrimary)
                }

                SurveyQuestion(title: "When do you prefer to do deep focused work?") {
                    ChipSelector(
                        options: TimeOfDayPreference.allCases,
                        selected: $survey.deepWorkPreference
                    )
                }

                SurveyQuestion(title: "How many hours of deep work per day?") {
                    Stepper("\(survey.deepWorkHoursTarget) hours", value: $survey.deepWorkHoursTarget, in: 1...10)
                        .font(AxiomTypography.body)
                        .foregroundStyle(AxiomColors.textPrimary)
                        .padding()
                        .background(AxiomColors.surface)
                        .cornerRadius(12)
                }

                SurveyQuestion(title: "Do you have fixed commitments?") {
                    Toggle("Fixed schedule commitments", isOn: $survey.hasFixedCommitments)
                        .font(AxiomTypography.body)
                        .foregroundStyle(AxiomColors.textPrimary)
                        .tint(AxiomColors.accent)
                        .padding()
                        .background(AxiomColors.surface)
                        .cornerRadius(12)
                }
            }
            .padding(AxiomSpacing.lg)
        }
    }
}

// MARK: - Section D: Routines

private struct RoutinesPage: View {
    @Binding var survey: SurveyResponse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AxiomSpacing.lg) {
                SurveyHeader(title: "Personal Routines", subtitle: "Your morning and evening rituals.")

                SurveyQuestion(title: "Do you have a morning routine?") {
                    Toggle("Morning routine", isOn: $survey.hasMorningRoutine)
                        .font(AxiomTypography.body)
                        .foregroundStyle(AxiomColors.textPrimary)
                        .tint(AxiomColors.accent)
                        .padding()
                        .background(AxiomColors.surface)
                        .cornerRadius(12)
                }

                if survey.hasMorningRoutine {
                    SurveyQuestion(title: "What's in your morning routine?") {
                        MultiChipSelector(
                            options: RoutineItem.allCases,
                            selected: $survey.morningRoutineItems
                        )
                    }

                    SurveyQuestion(title: "How long is your morning routine?") {
                        Stepper("\(survey.morningRoutineMinutes) min", value: $survey.morningRoutineMinutes, in: 5...120, step: 5)
                            .font(AxiomTypography.body)
                            .foregroundStyle(AxiomColors.textPrimary)
                            .padding()
                            .background(AxiomColors.surface)
                            .cornerRadius(12)
                    }
                }

                SurveyQuestion(title: "Do you have an evening wind-down routine?") {
                    Toggle("Evening routine", isOn: $survey.hasEveningRoutine)
                        .font(AxiomTypography.body)
                        .foregroundStyle(AxiomColors.textPrimary)
                        .tint(AxiomColors.accent)
                        .padding()
                        .background(AxiomColors.surface)
                        .cornerRadius(12)
                }

                if survey.hasEveningRoutine {
                    SurveyQuestion(title: "What's in your evening routine?") {
                        MultiChipSelector(
                            options: RoutineItem.allCases,
                            selected: $survey.eveningRoutineItems
                        )
                    }

                    SurveyQuestion(title: "How long is your evening routine?") {
                        Stepper("\(survey.eveningRoutineMinutes) min", value: $survey.eveningRoutineMinutes, in: 5...120, step: 5)
                            .font(AxiomTypography.body)
                            .foregroundStyle(AxiomColors.textPrimary)
                            .padding()
                            .background(AxiomColors.surface)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(AxiomSpacing.lg)
        }
    }
}

// MARK: - Section E: Priorities

private struct PrioritiesPage: View {
    @Binding var survey: SurveyResponse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AxiomSpacing.lg) {
                SurveyHeader(title: "Priorities & Values", subtitle: "What matters most to you right now.")

                SurveyQuestion(title: "Select your top 3 life areas.") {
                    MultiChipSelector(
                        options: LifeArea.allCases,
                        selected: $survey.topPriorities,
                        maxSelection: 3
                    )
                }

                SurveyQuestion(title: "How do you feel about social accountability?") {
                    ChipSelector(
                        options: AccountabilityFeel.allCases,
                        selected: $survey.socialAccountabilityFeel
                    )
                }

                SurveyQuestion(title: "One thing you want to do every single day without fail?") {
                    TextField("e.g. Read for 30 minutes", text: $survey.dailyNonNegotiable)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(AxiomColors.surface)
                        .cornerRadius(12)
                        .foregroundStyle(AxiomColors.textPrimary)
                }
            }
            .padding(AxiomSpacing.lg)
        }
    }
}

// MARK: - Shared Survey Components

private struct SurveyHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AxiomSpacing.xs) {
            Text(title)
                .font(AxiomTypography.title1)
                .foregroundStyle(AxiomColors.textPrimary)
            Text(subtitle)
                .font(AxiomTypography.caption)
                .foregroundStyle(AxiomColors.textSecondary)
        }
    }
}

private struct SurveyQuestion<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
            Text(title)
                .font(AxiomTypography.headline)
                .foregroundStyle(AxiomColors.textPrimary)
            content
        }
    }
}

struct ChipSelector<T: Identifiable & Hashable>: View where T: RawRepresentable, T.RawValue == String {
    let options: [T]
    @Binding var selected: T

    var body: some View {
        FlowLayout(spacing: AxiomSpacing.sm) {
            ForEach(options) { option in
                Button {
                    selected = option
                } label: {
                    Text(option.rawValue)
                        .font(AxiomTypography.caption)
                        .padding(.horizontal, AxiomSpacing.md)
                        .padding(.vertical, AxiomSpacing.sm)
                        .background(selected.id == option.id ? AxiomColors.accent : AxiomColors.surface)
                        .foregroundStyle(selected.id == option.id ? .white : AxiomColors.textPrimary)
                        .cornerRadius(20)
                }
            }
        }
    }
}

struct MultiChipSelector<T: Identifiable & Hashable>: View where T: RawRepresentable, T.RawValue == String {
    let options: [T]
    @Binding var selected: [T]
    var maxSelection: Int? = nil

    var body: some View {
        FlowLayout(spacing: AxiomSpacing.sm) {
            ForEach(options) { option in
                Button {
                    toggleSelection(option)
                } label: {
                    Text(option.rawValue)
                        .font(AxiomTypography.caption)
                        .padding(.horizontal, AxiomSpacing.md)
                        .padding(.vertical, AxiomSpacing.sm)
                        .background(selected.contains(where: { $0.id == option.id }) ? AxiomColors.accent : AxiomColors.surface)
                        .foregroundStyle(selected.contains(where: { $0.id == option.id }) ? .white : AxiomColors.textPrimary)
                        .cornerRadius(20)
                }
            }
        }
    }

    private func toggleSelection(_ option: T) {
        if let index = selected.firstIndex(where: { $0.id == option.id }) {
            selected.remove(at: index)
        } else {
            if let max = maxSelection, selected.count >= max {
                selected.removeFirst()
            }
            selected.append(option)
        }
    }
}

struct MealTimePicker: View {
    let label: String
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        HStack {
            Text(label)
                .font(AxiomTypography.body)
                .foregroundStyle(AxiomColors.textPrimary)
            Spacer()
            Picker("Hour", selection: $hour) {
                ForEach(5...22, id: \.self) { h in
                    let display = h > 12 ? h - 12 : h
                    let period = h >= 12 ? "PM" : "AM"
                    Text("\(display):00 \(period)").tag(h)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(AxiomColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
