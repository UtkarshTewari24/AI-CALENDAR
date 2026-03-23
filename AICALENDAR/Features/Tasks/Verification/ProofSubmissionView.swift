import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ProofSubmissionView: View {
    let task: AxiomTask
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var proofText = ""
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var isVerifying = false
    @State private var verificationResult: VerificationResult?
    @State private var errorMessage: String?

    private var needsPhoto: Bool {
        task.verificationMethod == .photo || task.verificationMethod == .both
    }

    private var needsText: Bool {
        task.verificationMethod == .text || task.verificationMethod == .both
    }

    private var canSubmit: Bool {
        if needsPhoto && capturedImage == nil { return false }
        if needsText && proofText.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AxiomSpacing.lg) {
                    // Task info
                    VStack(alignment: .leading, spacing: AxiomSpacing.xs) {
                        Text(task.title)
                            .font(AxiomTypography.title2)
                            .foregroundStyle(AxiomColors.textPrimary)
                        if !task.whatCountsAsDone.isEmpty {
                            Text("What counts as done: \(task.whatCountsAsDone)")
                                .font(AxiomTypography.caption)
                                .foregroundStyle(AxiomColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Photo proof
                    if needsPhoto {
                        VStack(spacing: AxiomSpacing.sm) {
                            Text("Photo Proof")
                                .font(AxiomTypography.headline)
                                .foregroundStyle(AxiomColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let image = capturedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)

                                Button("Retake") { showCamera = true }
                                    .font(AxiomTypography.caption)
                                    .foregroundStyle(AxiomColors.accent)
                            } else {
                                Button {
                                    showCamera = true
                                } label: {
                                    VStack(spacing: AxiomSpacing.sm) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 32))
                                        Text("Take Photo")
                                            .font(AxiomTypography.body)
                                    }
                                    .foregroundStyle(AxiomColors.accent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 150)
                                    .background(AxiomColors.surface)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // Text proof
                    if needsText {
                        VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
                            Text("Text Proof")
                                .font(AxiomTypography.headline)
                                .foregroundStyle(AxiomColors.textPrimary)

                            TextField("Describe how you completed this task...", text: $proofText, axis: .vertical)
                                .lineLimit(5...10)
                                .padding()
                                .background(AxiomColors.surface)
                                .cornerRadius(12)
                                .foregroundStyle(AxiomColors.textPrimary)
                        }
                    }

                    // Verification result
                    if let result = verificationResult {
                        VStack(spacing: AxiomSpacing.sm) {
                            Image(systemName: result.verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(result.verified ? AxiomColors.success : AxiomColors.destructive)

                            Text(result.verified ? "Verified!" : "Not Verified")
                                .font(AxiomTypography.title2)
                                .foregroundStyle(result.verified ? AxiomColors.success : AxiomColors.destructive)

                            Text(result.reason)
                                .font(AxiomTypography.caption)
                                .foregroundStyle(AxiomColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(AxiomSpacing.lg)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(AxiomTypography.caption)
                            .foregroundStyle(AxiomColors.destructive)
                    }

                    // Submit button
                    if verificationResult == nil || verificationResult?.verified == false {
                        Button {
                            Task { await submitProof() }
                        } label: {
                            if isVerifying {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("AI is reviewing your proof...")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(AxiomColors.accent.opacity(0.7))
                                .foregroundStyle(.white)
                                .font(AxiomTypography.headline)
                                .cornerRadius(12)
                            } else {
                                Text("Submit Proof")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(canSubmit ? AxiomColors.accent : AxiomColors.surface)
                                    .foregroundStyle(canSubmit ? .white : AxiomColors.textSecondary)
                                    .font(AxiomTypography.headline)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(!canSubmit || isVerifying)
                    }

                    if verificationResult?.verified == true {
                        Button("Done") { dismiss() }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AxiomColors.success)
                            .foregroundStyle(.white)
                            .font(AxiomTypography.headline)
                            .cornerRadius(12)
                    }
                }
                .padding(AxiomSpacing.lg)
            }
            .background(AxiomColors.backgroundPrimary)
            .navigationTitle("Submit Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView(image: $capturedImage)
            }
        }
    }

    private func submitProof() async {
        isVerifying = true
        errorMessage = nil

        let imageData: Data? = if let image = capturedImage {
            VerificationService.compressImage(image)
        } else {
            nil
        }

        do {
            let result = try await VerificationService.verify(
                task: task,
                proofText: proofText.isEmpty ? nil : proofText,
                proofImage: imageData
            )

            verificationResult = result

            if result.verified {
                task.status = .completed
                task.verifiedAt = Date()
                task.proofText = proofText.isEmpty ? nil : proofText
                if let data = try? JSONEncoder().encode(result) {
                    task.verificationResponse = String(data: data, encoding: .utf8)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isVerifying = false
    }
}
