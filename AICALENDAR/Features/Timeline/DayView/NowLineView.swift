import SwiftUI

struct NowLineView: View {
    let hourHeight: CGFloat

    @State private var currentTime = Date()

    var body: some View {
        let minutes = currentTime.minutesSinceStartOfDay()
        let yOffset = minutes / 60.0 * hourHeight

        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                // Red dot
                Circle()
                    .fill(AxiomColors.nowLine)
                    .frame(width: TimelineConstants.nowLineDotSize, height: TimelineConstants.nowLineDotSize)
                    .offset(x: TimelineConstants.hourLabelWidth - TimelineConstants.nowLineDotSize / 2)

                // Red line
                Rectangle()
                    .fill(AxiomColors.nowLine)
                    .frame(height: 2)
            }
            .offset(y: yOffset)

            // Time label
            Text(currentTime.formattedShortTime)
                .font(AxiomTypography.micro)
                .foregroundStyle(AxiomColors.nowLine)
                .offset(x: 4, y: yOffset - 8)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                currentTime = Date()
            }
        }
    }
}
