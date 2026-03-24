import Foundation

enum IconSuggestionService {

    /// Suggest an SF Symbol icon based on event title and type (keyword-based, no API call)
    static func suggestIcon(title: String, type: EventType) -> String {
        let lowered = title.lowercased()

        let keywordMap: [(keywords: [String], icon: String)] = [
            (["gym", "lift", "squat", "bench", "weight"], "dumbbell.fill"),
            (["run", "jog", "sprint", "running"], "figure.run"),
            (["yoga", "stretch", "flexibility"], "figure.mind.and.body"),
            (["swim", "pool", "lap"], "figure.pool.swim"),
            (["bike", "cycle", "cycling"], "bicycle"),
            (["hike", "hiking", "trail"], "figure.hiking"),
            (["walk", "walking", "stroll"], "figure.walk"),
            (["code", "program", "dev", "coding"], "chevron.left.forwardslash.chevron.right"),
            (["meeting", "call", "standup", "sync"], "phone.fill"),
            (["email", "inbox", "mail"], "envelope.fill"),
            (["read", "book", "study", "learn"], "book.fill"),
            (["write", "journal", "blog", "essay"], "pencil.and.outline"),
            (["breakfast", "coffee", "morning"], "cup.and.saucer.fill"),
            (["lunch", "dinner", "eat", "food"], "fork.knife"),
            (["cook", "prep", "kitchen", "recipe"], "frying.pan.fill"),
            (["sleep", "nap", "rest", "bed"], "moon.fill"),
            (["meditate", "mindful", "breathe"], "brain.head.profile"),
            (["shower", "hygiene", "brush"], "shower.fill"),
            (["drive", "commute", "car", "travel"], "car.fill"),
            (["music", "practice", "piano", "guitar", "sing"], "music.note"),
            (["clean", "tidy", "laundry", "chore"], "washer.fill"),
            (["shop", "grocery", "errand", "store"], "cart.fill"),
            (["doctor", "dentist", "health", "appointment"], "cross.case.fill"),
            (["class", "lecture", "school", "university"], "graduationcap.fill"),
            (["present", "slides", "talk", "speech"], "person.wave.2.fill"),
        ]

        for entry in keywordMap {
            if entry.keywords.contains(where: { lowered.contains($0) }) {
                return entry.icon
            }
        }

        // Fall back to event type default
        return type.defaultIcon
    }

    /// Common SF Symbols for manual icon picker
    static let commonIcons: [String] = [
        "figure.run", "dumbbell.fill", "bicycle", "figure.walk",
        "laptopcomputer", "book.fill", "pencil.and.outline",
        "fork.knife", "cup.and.saucer.fill", "moon.fill",
        "phone.fill", "envelope.fill", "car.fill",
        "music.note", "graduationcap.fill", "heart.fill",
        "star.fill", "bolt.fill", "leaf.fill", "cart.fill",
        "person.fill", "house.fill", "arrow.clockwise",
        "brain.head.profile"
    ]
}
