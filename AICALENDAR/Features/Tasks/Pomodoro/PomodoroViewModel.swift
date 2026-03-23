import SwiftUI

@Observable
final class PomodoroViewModel {
    enum PomodoroState {
        case idle
        case running
        case paused
        case sessionComplete
        case onBreak
        case breakComplete
    }

    let taskId: UUID
    let durationMinutes: Int
    let breakMinutes: Int = 5

    var state: PomodoroState = .idle
    var elapsedSeconds: Double = 0
    var sessionStartTime: Date?
    var sessionCompleted = false

    private var totalSeconds: Double { Double(durationMinutes * 60) }
    private var breakTotalSeconds: Double { Double(breakMinutes * 60) }

    var progress: Double {
        switch state {
        case .idle: return 0
        case .running, .paused:
            return min(elapsedSeconds / totalSeconds, 1.0)
        case .sessionComplete: return 1.0
        case .onBreak:
            return min(elapsedSeconds / breakTotalSeconds, 1.0)
        case .breakComplete: return 1.0
        }
    }

    var stateLabel: String {
        switch state {
        case .idle: return "Tap Start to begin"
        case .running: return "Focus time — tap clock to pause"
        case .paused: return "Paused — tap clock to resume"
        case .sessionComplete: return "Session complete!"
        case .onBreak: return "Break time..."
        case .breakComplete: return "Break over!"
        }
    }

    init(taskId: UUID, durationMinutes: Int) {
        self.taskId = taskId
        self.durationMinutes = durationMinutes
    }

    func start() {
        state = .running
        elapsedSeconds = 0
        sessionStartTime = Date()
    }

    func togglePause() {
        if state == .running {
            state = .paused
        } else if state == .paused {
            state = .running
        }
    }

    func startBreak() {
        state = .onBreak
        elapsedSeconds = 0

        if UserDefaultsService.pomodoroBreakReminder {
            NotificationService.schedulePomodoroBreakEnd()
        }
    }

    func startNewSession() {
        state = .running
        elapsedSeconds = 0
        sessionStartTime = Date()
    }

    func run() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(100))

            switch state {
            case .running:
                elapsedSeconds += 0.1
                if elapsedSeconds >= totalSeconds {
                    state = .sessionComplete
                    sessionCompleted = true
                }

            case .onBreak:
                elapsedSeconds += 0.1
                if elapsedSeconds >= breakTotalSeconds {
                    state = .breakComplete
                }

            default:
                break
            }
        }
    }
}
