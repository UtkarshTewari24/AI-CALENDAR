import SwiftUI

struct ConfirmationCard: View {
    let action: PendingAction
    let onApply: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AxiomSpacing.md) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(AxiomColors.accent)
                Text("Proposed Changes")
                    .font(AxiomTypography.headline)
                    .foregroundStyle(AxiomColors.textPrimary)
            }

            Text(action.description)
                .font(AxiomTypography.body)
                .foregroundStyle(AxiomColors.textSecondary)

            HStack(spacing: AxiomSpacing.md) {
                Button("Cancel") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AxiomColors.surface)
                .foregroundStyle(AxiomColors.textPrimary)
                .font(AxiomTypography.headline)
                .cornerRadius(10)

                Button("Apply Changes") {
                    onApply()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AxiomColors.accent)
                .foregroundStyle(.white)
                .font(AxiomTypography.headline)
                .cornerRadius(10)
            }
        }
        .padding(AxiomSpacing.md)
        .background(AxiomColors.surface)
        .cornerRadius(16)
        .padding(.horizontal, AxiomSpacing.md)
    }
}
