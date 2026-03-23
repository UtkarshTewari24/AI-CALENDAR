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

    var accentColor: Color {
        Color(hex: accentColorHex)
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
}
