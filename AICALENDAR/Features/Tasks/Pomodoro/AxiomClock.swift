import SwiftUI

struct AxiomClock: View {
    let progress: Double
    var isBreak: Bool = false
    var isPaused: Bool = false

    private var handColor: Color {
        isBreak ? AxiomColors.success : AxiomColors.destructive
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 8

            // Outer ring
            let ringPath = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.stroke(ringPath, with: .color(AxiomColors.surface), lineWidth: 3)

            // Tick marks at 5-minute intervals (12 marks for 25 min, or proportional)
            let tickCount = 12
            for i in 0..<tickCount {
                let angle = Angle.degrees(Double(i) / Double(tickCount) * 360 - 90)
                let outerPoint = pointOnCircle(center: center, radius: radius - 2, angle: angle)
                let isMajor = i % 3 == 0
                let innerPoint = pointOnCircle(center: center, radius: radius - (isMajor ? 16 : 10), angle: angle)

                var tickPath = Path()
                tickPath.move(to: outerPoint)
                tickPath.addLine(to: innerPoint)
                context.stroke(tickPath, with: .color(AxiomColors.textSecondary.opacity(0.5)), lineWidth: isMajor ? 2 : 1)
            }

            // Center dot
            let dotSize: CGFloat = 8
            let dotRect = CGRect(x: center.x - dotSize / 2, y: center.y - dotSize / 2, width: dotSize, height: dotSize)
            context.fill(Path(ellipseIn: dotRect), with: .color(handColor))

            // Sweep hand
            let handAngle = Angle.degrees(progress * 360 - 90)
            let handLength = radius - 24
            let handEnd = pointOnCircle(center: center, radius: handLength, angle: handAngle)

            var handPath = Path()
            handPath.move(to: center)
            handPath.addLine(to: handEnd)
            context.stroke(handPath, with: .color(handColor), lineWidth: 3)

            // Hand tip circle
            let tipSize: CGFloat = 6
            let tipRect = CGRect(x: handEnd.x - tipSize / 2, y: handEnd.y - tipSize / 2, width: tipSize, height: tipSize)
            context.fill(Path(ellipseIn: tipRect), with: .color(handColor))

            // Progress arc (swept area)
            var arcPath = Path()
            arcPath.move(to: center)
            arcPath.addArc(
                center: center,
                radius: radius - 24,
                startAngle: .degrees(-90),
                endAngle: .degrees(progress * 360 - 90),
                clockwise: false
            )
            arcPath.closeSubpath()
            context.fill(arcPath, with: .color(handColor.opacity(0.08)))
        }
        .opacity(isPaused ? 0.5 : 1.0)
        .animation(.linear(duration: 0.1), value: progress)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(CGFloat(angle.radians)),
            y: center.y + radius * sin(CGFloat(angle.radians))
        )
    }
}
