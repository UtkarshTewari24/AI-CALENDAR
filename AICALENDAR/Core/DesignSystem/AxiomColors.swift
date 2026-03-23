import SwiftUI

enum AxiomColors {
    // MARK: - Background
    static let backgroundPrimary = Color(hex: "#0A0A0F")
    static let backgroundSecondary = Color(hex: "#16161F")
    static let surface = Color(hex: "#1F1F2E")

    // MARK: - Accent
    static let accent = Color(hex: "#6C63FF")
    static let accentMuted = Color(hex: "#3D3580")

    // MARK: - Text
    static let textPrimary = Color(hex: "#F9FAFB")
    static let textSecondary = Color(hex: "#9CA3AF")

    // MARK: - Semantic
    static let destructive = Color(hex: "#EF4444")
    static let success = Color(hex: "#22C55E")
    static let nowLine = Color(hex: "#EF4444")

    // MARK: - Event Type Colors
    static let workout = Color(hex: "#F97316")
    static let work = Color(hex: "#3B82F6")
    static let meal = Color(hex: "#22C55E")
    static let routine = Color(hex: "#A855F7")
    static let personal = Color(hex: "#14B8A6")
    static let sleep = Color(hex: "#6366F1")
    static let taskDeadline = Color(hex: "#EF4444")

    static func color(for eventType: EventType) -> Color {
        switch eventType {
        case .workout: return workout
        case .work: return work
        case .meal: return meal
        case .routine: return routine
        case .personal: return personal
        case .sleep: return sleep
        case .taskDeadline: return taskDeadline
        }
    }

    // MARK: - Preset Accent Colors
    static let presetAccents: [(name: String, hex: String)] = [
        ("Purple", "#6C63FF"),
        ("Blue", "#3B82F6"),
        ("Green", "#22C55E"),
        ("Orange", "#F97316"),
        ("Pink", "#EC4899"),
        ("Red", "#EF4444"),
        ("Teal", "#14B8A6"),
        ("Indigo", "#6366F1"),
        ("Yellow", "#EAB308"),
        ("Cyan", "#06B6D4"),
        ("Fuchsia", "#D946EF"),
        ("Rose", "#F43F5E")
    ]
}
