import SwiftUI

struct ScheduleGenerationView: View {
    @Bindable var coordinator: OnboardingCoordinator

    @State private var loadingMessageIndex = 0
    @State private var isSpinning = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var dotOffsets: [CGFloat] = [0, 0, 0]

    private let loadingMessages = [
        "Analyzing your daily rhythm...",
        "Blocking your gym sessions...",
        "Protecting your deep work window...",
        "Fitting in recovery time...",
        "Optimizing meal timing...",
        "Building your weekly structure...",
        "Fine-tuning priorities..."
    ]

    var body: some View {
        ZStack {
            AxiomColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: AxiomSpacing.xl) {
                Spacer()

                // Animated loading indicator
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(AxiomColors.accent.opacity(0.2), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - Double(pulseScale))

                    // Track circle
                    Circle()
                        .stroke(AxiomColors.surface, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    // Spinning arc
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(AxiomColors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isSpinning ? 360 : 0))

                    // Center icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(AxiomColors.accent)
                        .symbolEffect(.pulse, isActive: isSpinning)
                }

                Text("Building your personalized schedule")
                    .font(AxiomTypography.title2)
                    .foregroundStyle(AxiomColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AxiomSpacing.lg)

                // Animated dots row
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(AxiomColors.accent)
                            .frame(width: 6, height: 6)
                            .offset(y: dotOffsets[index])
                    }
                }

                Text(loadingMessages[loadingMessageIndex])
                    .font(AxiomTypography.caption)
                    .foregroundStyle(AxiomColors.textSecondary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: loadingMessageIndex)

                Spacer()

                if let error = coordinator.generationError {
                    VStack(spacing: AxiomSpacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundStyle(AxiomColors.destructive)

                        Text(error)
                            .font(AxiomTypography.caption)
                            .foregroundStyle(AxiomColors.destructive)
                            .multilineTextAlignment(.center)

                        Button {
                            Task { await coordinator.generateSchedule() }
                        } label: {
                            Text("Try Again")
                                .font(AxiomTypography.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(AxiomColors.accent)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, AxiomSpacing.lg)
                    .padding(.bottom, AxiomSpacing.xxl)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Spinner
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            isSpinning = true
        }

        // Pulse ring
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseScale = 1.4
        }

        // Bouncing dots
        for i in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.15)
            ) {
                dotOffsets[i] = -8
            }
        }

        // Cycling messages
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.5))
                loadingMessageIndex = (loadingMessageIndex + 1) % loadingMessages.count
            }
        }
    }
}
