import SwiftUI
import UIKit

struct PunishmentView: View {
    let task: AxiomTask
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    @State private var hasShared = false
    @State private var showShareSheet = false

    private var punishmentText: String {
        "I failed to complete '\(task.title)' by \(task.deadline.formattedDate) at \(task.deadline.formattedTime). Accountability post via Axiom. #accountability #discipline"
    }

    var body: some View {
        ZStack {
            AxiomColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: AxiomSpacing.xl) {
                Spacer()

                // Header
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AxiomColors.destructive)

                Text("You missed a commitment.")
                    .font(AxiomTypography.title1)
                    .foregroundStyle(AxiomColors.destructive)

                // Body
                VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
                    Text("You committed to:")
                        .font(AxiomTypography.caption)
                        .foregroundStyle(AxiomColors.textSecondary)
                    Text(task.title)
                        .font(AxiomTypography.title2)
                        .foregroundStyle(AxiomColors.textPrimary)
                    Text("Due: \(task.deadline.formattedDate) at \(task.deadline.formattedTime)")
                        .font(AxiomTypography.mono)
                        .foregroundStyle(AxiomColors.textSecondary)
                }
                .padding(AxiomSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AxiomColors.surface)
                .cornerRadius(12)
                .padding(.horizontal, AxiomSpacing.lg)

                // Post preview (verbatim, not editable per OQ-1)
                VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
                    Text("Your accountability post:")
                        .font(AxiomTypography.micro)
                        .foregroundStyle(AxiomColors.textSecondary)
                    Text(punishmentText)
                        .font(AxiomTypography.body)
                        .foregroundStyle(AxiomColors.textPrimary)
                        .padding(AxiomSpacing.md)
                        .background(AxiomColors.surface)
                        .cornerRadius(8)
                }
                .padding(.horizontal, AxiomSpacing.lg)

                Spacer()

                // Post button
                Button {
                    showShareSheet = true
                } label: {
                    Text("Post Now")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AxiomColors.destructive)
                        .foregroundStyle(.white)
                        .font(AxiomTypography.headline)
                        .cornerRadius(12)
                }
                .padding(.horizontal, AxiomSpacing.lg)

                if hasShared {
                    Button("I've posted it") {
                        task.isPunished = true
                        onComplete()
                    }
                    .font(AxiomTypography.headline)
                    .foregroundStyle(AxiomColors.textPrimary)
                    .padding(.bottom, AxiomSpacing.lg)
                } else {
                    Text("You must share to continue using Axiom.")
                        .font(AxiomTypography.micro)
                        .foregroundStyle(AxiomColors.textSecondary)
                        .padding(.bottom, AxiomSpacing.lg)
                }
            }
        }
        .interactiveDismissDisabled()
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [punishmentText])
                .onDisappear {
                    hasShared = true
                }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
