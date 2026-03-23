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
                                    .stroke(Color.white, lineWidth: theme.accentColorHex == preset.hex ? 3 : 0)
                            )
                            .onTapGesture {
                                theme.accentColorHex = preset.hex
                            }
                    }
                }
                .padding(.vertical, AxiomSpacing.sm)
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
