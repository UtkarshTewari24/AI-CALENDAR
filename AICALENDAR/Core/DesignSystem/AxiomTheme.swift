import SwiftUI

@Observable
final class ThemeManager {
    var colorSchemePreference: AppColorSchemePreference {
        didSet { UserDefaultsService.colorScheme = colorSchemePreference }
    }

    var accentColorHex: String {
        didSet { UserDefaultsService.accentColorHex = accentColorHex }
    }

    var timelineDensity: TimelineDensity {
        didSet { UserDefaultsService.timelineDensity = timelineDensity }
    }

    var fontSizePreference: FontSizePreference {
        didSet { UserDefaultsService.fontSize = fontSizePreference }
    }

    var showNowLine: Bool {
        didSet { UserDefaultsService.showNowLine = showNowLine }
    }

    var animateNowLine: Bool {
        didSet { UserDefaultsService.animateNowLine = animateNowLine }
    }

    // Punishment blink state
    var isBlinkingActive = false
    var blinkPhase = false
    private var blinkTimer: Timer?

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    /// Use this instead of accentColor throughout the app — respects punishment blink
    var effectiveAccentColor: Color {
        if isBlinkingActive {
            return blinkPhase ? Color.red : Color.white
        }
        return accentColor
    }

    var resolvedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var hourHeight: CGFloat {
        timelineDensity.hourHeight
    }

    init() {
        self.colorSchemePreference = UserDefaultsService.colorScheme
        self.accentColorHex = UserDefaultsService.accentColorHex
        self.timelineDensity = UserDefaultsService.timelineDensity
        self.fontSizePreference = UserDefaultsService.fontSize
        self.showNowLine = UserDefaultsService.showNowLine
        self.animateNowLine = UserDefaultsService.animateNowLine
    }

    func startPunishmentBlink() {
        guard UserDefaultsService.punishmentBlinkEnabled else { return }
        guard !isBlinkingActive else { return }
        isBlinkingActive = true
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.blinkPhase.toggle()
        }
    }

    func stopPunishmentBlink() {
        isBlinkingActive = false
        blinkPhase = false
        blinkTimer?.invalidate()
        blinkTimer = nil
    }
}
