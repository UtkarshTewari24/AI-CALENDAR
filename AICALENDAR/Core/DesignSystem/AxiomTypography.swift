import SwiftUI

enum AxiomTypography {
    // SF Pro Display — for hero and section headers
    static let displayBold = Font.system(size: 34, weight: .bold, design: .default)
    static let title1 = Font.system(size: 28, weight: .semibold, design: .default)

    // SF Pro Rounded — for card titles
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)

    // SF Pro Text — for body content
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let caption = Font.system(size: 15, weight: .regular, design: .default)

    // SF Mono — for time displays
    static let mono = Font.system(size: 15, weight: .regular, design: .monospaced)

    // Micro — for badges
    static let micro = Font.system(size: 12, weight: .semibold, design: .default)
}
