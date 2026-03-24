import SwiftUI
import SwiftData

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var theme
    @Query(sort: \AxiomTask.deadline) private var allTasks: [AxiomTask]
    @Query private var profiles: [UserProfile]

    @State private var viewModel = ProgressViewModel()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AxiomSpacing.lg) {
                    streakCard
                    completionChainCard
                    completionRateCard
                    timelinessCard
                }
                .padding(AxiomSpacing.md)
            }
            .background(AxiomColors.backgroundPrimary)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                HStack {
                    Text("Progress")
                        .font(AxiomTypography.headline)
                        .foregroundStyle(AxiomColors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, AxiomSpacing.md)
                .padding(.vertical, AxiomSpacing.sm)
                .background(AxiomColors.backgroundPrimary)
            }
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: AxiomSpacing.lg) {
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(theme.effectiveAccentColor)
                Text("\(profile?.currentStreak ?? 0)")
                    .font(AxiomTypography.title1)
                    .foregroundStyle(AxiomColors.textPrimary)
                Text("Day Streak")
                    .font(AxiomTypography.micro)
                    .foregroundStyle(AxiomColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 28))
                    .foregroundStyle(theme.effectiveAccentColor)
                Text("\(profile?.itemsCompletedInARow ?? 0)")
                    .font(AxiomTypography.title1)
                    .foregroundStyle(AxiomColors.textPrimary)
                Text("In a Row")
                    .font(AxiomTypography.micro)
                    .foregroundStyle(AxiomColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AxiomColors.success)
                Text("\(profile?.longestStreak ?? 0)")
                    .font(AxiomTypography.title1)
                    .foregroundStyle(AxiomColors.textPrimary)
                Text("Best")
                    .font(AxiomTypography.micro)
                    .foregroundStyle(AxiomColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(AxiomSpacing.lg)
        .background(AxiomColors.surface)
        .cornerRadius(16)
    }

    // MARK: - Completion Chain (30-day grid)

    private var completionChainCard: some View {
        let days = viewModel.computeLast30Days(tasks: allTasks)

        return VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
            Text("Last 30 Days")
                .font(AxiomTypography.headline)
                .foregroundStyle(AxiomColors.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days) { day in
                    Circle()
                        .fill(dayColor(for: day))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if Calendar.current.isDateInToday(day.date) {
                                Circle()
                                    .stroke(AxiomColors.textPrimary, lineWidth: 2)
                            }
                        }
                }
            }

            HStack(spacing: AxiomSpacing.md) {
                legendItem(color: AxiomColors.success, label: "All Done")
                legendItem(color: AxiomColors.destructive, label: "Failed")
                legendItem(color: theme.effectiveAccentColor.opacity(0.4), label: "Partial")
                legendItem(color: AxiomColors.backgroundSecondary, label: "No Tasks")
            }
            .font(AxiomTypography.micro)
        }
        .padding(AxiomSpacing.lg)
        .background(AxiomColors.surface)
        .cornerRadius(16)
    }

    // MARK: - Completion Rate

    private var completionRateCard: some View {
        let rate = viewModel.completionRate(tasks: allTasks)
        let total = profile?.totalTasksCompleted ?? 0

        return HStack {
            VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
                Text("Completion Rate")
                    .font(AxiomTypography.headline)
                    .foregroundStyle(AxiomColors.textPrimary)
                Text("\(total) tasks completed")
                    .font(AxiomTypography.caption)
                    .foregroundStyle(AxiomColors.textSecondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(AxiomColors.backgroundSecondary, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(theme.effectiveAccentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(rate * 100))%")
                    .font(AxiomTypography.headline)
                    .foregroundStyle(AxiomColors.textPrimary)
            }
            .frame(width: 64, height: 64)
        }
        .padding(AxiomSpacing.lg)
        .background(AxiomColors.surface)
        .cornerRadius(16)
    }

    // MARK: - Timeliness

    private var timelinessCard: some View {
        let avgTime = viewModel.averageTimeBeforeDeadline(tasks: allTasks)

        return VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
            Text("Timeliness")
                .font(AxiomTypography.headline)
                .foregroundStyle(AxiomColors.textPrimary)

            if let avg = avgTime {
                let isEarly = avg > 0
                let absMinutes = Int(abs(avg) / 60)
                let hours = absMinutes / 60
                let minutes = absMinutes % 60

                HStack(spacing: AxiomSpacing.sm) {
                    Image(systemName: isEarly ? "clock.badge.checkmark" : "clock.badge.exclamationmark")
                        .font(.system(size: 24))
                        .foregroundStyle(isEarly ? AxiomColors.success : AxiomColors.destructive)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isEarly ? "On average, early" : "On average, late")
                            .font(AxiomTypography.caption)
                            .foregroundStyle(AxiomColors.textSecondary)
                        Text(hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m")
                            .font(AxiomTypography.title2)
                            .foregroundStyle(isEarly ? AxiomColors.success : AxiomColors.destructive)
                    }
                }
            } else {
                Text("Complete some tasks to see your timeliness stats")
                    .font(AxiomTypography.caption)
                    .foregroundStyle(AxiomColors.textSecondary)
            }
        }
        .padding(AxiomSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AxiomColors.surface)
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func dayColor(for day: ProgressViewModel.DayCompletionData) -> Color {
        switch day.status {
        case .allCompleted: return AxiomColors.success
        case .hasFailed: return AxiomColors.destructive
        case .partial: return theme.effectiveAccentColor.opacity(0.4)
        case .noTasks: return AxiomColors.backgroundSecondary
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(AxiomColors.textSecondary)
        }
    }
}
