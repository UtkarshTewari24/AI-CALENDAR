import SwiftUI

struct EventTypePicker: View {
    @Binding var selectedType: EventType

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AxiomSpacing.sm) {
                ForEach(EventType.allCases.filter { $0 != .taskDeadline }) { type in
                    Button {
                        selectedType = type
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AxiomColors.color(for: type))
                                .frame(width: 8, height: 8)
                            Text(type.displayName)
                                .font(AxiomTypography.micro)
                        }
                        .padding(.horizontal, AxiomSpacing.md)
                        .padding(.vertical, AxiomSpacing.sm)
                        .background(
                            Capsule()
                                .fill(selectedType == type ? AxiomColors.color(for: type).opacity(0.2) : AxiomColors.surface)
                        )
                        .overlay(
                            Capsule()
                                .stroke(selectedType == type ? AxiomColors.color(for: type) : Color.clear, lineWidth: 1)
                        )
                        .foregroundStyle(AxiomColors.textPrimary)
                    }
                }
            }
            .padding(.vertical, AxiomSpacing.xs)
        }
    }
}
