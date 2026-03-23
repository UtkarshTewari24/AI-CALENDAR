import SwiftUI
import SwiftData

struct TasksView: View {
    @State private var viewModel = TasksViewModel()
    @Query(sort: \AxiomTask.deadline) private var allTasks: [AxiomTask]

    var body: some View {
        NavigationStack {
            ZStack {
                AxiomColors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AxiomSpacing.sm) {
                            ForEach(TaskFilter.allCases) { filter in
                                Button {
                                    viewModel.selectedFilter = filter
                                } label: {
                                    Text(filter.rawValue)
                                        .font(AxiomTypography.caption)
                                        .padding(.horizontal, AxiomSpacing.md)
                                        .padding(.vertical, AxiomSpacing.sm)
                                        .background(viewModel.selectedFilter == filter ? AxiomColors.accent : AxiomColors.surface)
                                        .foregroundStyle(viewModel.selectedFilter == filter ? .white : AxiomColors.textPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, AxiomSpacing.md)
                        .padding(.vertical, AxiomSpacing.sm)
                    }

                    // Task list
                    let filtered = viewModel.filteredTasks(from: allTasks)

                    if filtered.upcoming.isEmpty && filtered.completed.isEmpty {
                        Spacer()
                        VStack(spacing: AxiomSpacing.md) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundStyle(AxiomColors.textSecondary.opacity(0.5))
                            Text("No tasks yet")
                                .font(AxiomTypography.body)
                                .foregroundStyle(AxiomColors.textSecondary)
                            Text("Tap + to create your first task")
                                .font(AxiomTypography.caption)
                                .foregroundStyle(AxiomColors.textSecondary.opacity(0.7))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AxiomSpacing.sm) {
                                if !filtered.upcoming.isEmpty {
                                    Section {
                                        ForEach(filtered.upcoming, id: \.id) { task in
                                            NavigationLink(value: task.id) {
                                                AxiomTaskRow(task: task)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    } header: {
                                        SectionHeader(title: "Upcoming", count: filtered.upcoming.count)
                                    }
                                }

                                if !filtered.completed.isEmpty {
                                    Section {
                                        ForEach(filtered.completed, id: \.id) { task in
                                            NavigationLink(value: task.id) {
                                                AxiomTaskRow(task: task)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    } header: {
                                        SectionHeader(title: "Completed", count: filtered.completed.count)
                                    }
                                }
                            }
                            .padding(.horizontal, AxiomSpacing.md)
                            .padding(.bottom, AxiomSpacing.lg)
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AxiomColors.accent)
                    }
                }
            }
            .navigationDestination(for: UUID.self) { taskId in
                if let task = allTasks.first(where: { $0.id == taskId }) {
                    TaskDetailView(task: task)
                }
            }
            .sheet(isPresented: $viewModel.showingAddTask) {
                AddTaskView()
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(AxiomTypography.headline)
                .foregroundStyle(AxiomColors.textPrimary)
            Text("\(count)")
                .font(AxiomTypography.micro)
                .foregroundStyle(AxiomColors.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AxiomColors.surface)
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.top, AxiomSpacing.md)
        .padding(.bottom, AxiomSpacing.xs)
    }
}
