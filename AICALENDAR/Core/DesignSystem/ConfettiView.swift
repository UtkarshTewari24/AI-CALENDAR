import SwiftUI

struct ConfettiView: View {
    @Environment(ThemeManager.self) private var theme
    @Binding var isActive: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        if isActive {
            GeometryReader { geo in
                Canvas { context, size in
                    for particle in particles {
                        let rect = CGRect(
                            x: particle.x - particle.size / 2,
                            y: particle.y - particle.size / 2,
                            width: particle.size,
                            height: particle.size * 0.6
                        )

                        context.fill(
                            Path(roundedRect: rect, cornerRadius: 2),
                            with: .color(particle.color)
                        )
                    }
                }
                .onAppear {
                    canvasSize = geo.size
                    generateParticles()
                    animateParticles()
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func generateParticles() {
        let colors: [Color] = [
            theme.effectiveAccentColor,
            AxiomColors.success,
            AxiomColors.workout,
            AxiomColors.work,
            AxiomColors.routine,
            .yellow,
            .pink
        ]

        let width = canvasSize.width

        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...max(width, 1)),
                y: CGFloat.random(in: -100...(-10)),
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement() ?? .white,
                velocityX: CGFloat.random(in: -2...2),
                velocityY: CGFloat.random(in: 2...8),
                rotation: CGFloat.random(in: 0...360)
            )
        }
    }

    private func animateParticles() {
        Task {
            for _ in 0..<120 {
                try? await Task.sleep(for: .milliseconds(16))
                for i in particles.indices {
                    particles[i].x += particles[i].velocityX
                    particles[i].y += particles[i].velocityY
                    particles[i].velocityY += 0.15 // gravity
                    particles[i].rotation += 5
                }
            }

            withAnimation {
                isActive = false
            }
            particles.removeAll()
        }
    }
}

private struct ConfettiParticle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var velocityX: CGFloat
    var velocityY: CGFloat
    var rotation: CGFloat
}
