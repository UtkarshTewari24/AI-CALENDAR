import SwiftUI

struct FreeTimeGapView: View {
    let gapMinutes: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AxiomSpacing.sm) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 14))
                    .foregroundStyle(AxiomColors.textSecondary.opacity(0.4))

                Text("You have \(gapMinutes) extra minutes here.\nWhat would you like to do?")
                    .font(AxiomTypography.micro)
                    .foregroundStyle(AxiomColors.textSecondary.opacity(0.4))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(AxiomSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AxiomColors.surface.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
        .buttonStyle(.plain)
    }
}
