import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        @Bindable var theme = theme

        Form {
            Section("Theme") {
                Picker("Color Scheme", selection: $theme.colorSchemePreference) {
                    ForEach(AppColorSchemePreference.allCases) { scheme in
                        Text(scheme.displayName).tag(scheme)
                    }
                }
            }

            Section("Accent Color") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                    ForEach(AxiomColors.presetAccents, id: \.hex) { preset in
                        Circle()
                            .fill(Color(hex: preset.hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(AxiomColors.textPrimary.opacity(0.9), lineWidth: theme.accentColorHex == preset.hex ? 2 : 0)
                            )
                            .onTapGesture {
                                theme.accentColorHex = preset.hex
                            }
                    }
                }
                .padding(.vertical, AxiomSpacing.sm)

                HStack(spacing: AxiomSpacing.md) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: theme.accentColorHex))
                        .frame(width: 24, height: 24)
                    Text("Current accent preview")
                        .font(AxiomTypography.caption)
                        .foregroundStyle(AxiomColors.textSecondary)
                }
            }

            Section("Timeline") {
                Picker("Density", selection: $theme.timelineDensity) {
                    ForEach(TimelineDensity.allCases) { density in
                        Text(density.displayName).tag(density)
                    }
                }

                Toggle("Show Now Line", isOn: $theme.showNowLine)
                Toggle("Animate Now Line", isOn: $theme.animateNowLine)
            }

            Section("Text") {
                Picker("Font Size", selection: $theme.fontSizePreference) {
                    ForEach(FontSizePreference.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }
            }
        }
        .navigationTitle("Appearance")
    }
}
