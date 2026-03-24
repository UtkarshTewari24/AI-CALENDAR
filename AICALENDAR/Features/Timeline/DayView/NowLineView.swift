import SwiftUI

struct NowLineView: View {
    let hourHeight: CGFloat

    @State private var currentTime = Date()

    var body: some View {
        let minutes = currentTime.minutesSinceStartOfDay()
        let yOffset = minutes / 60.0 * hourHeight

        // White text showing current time, positioned at the now offset
        Text(currentTime.formattedShortTime)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .frame(width: TimelineConstants.hourLabelWidth, alignment: .trailing)
            .padding(.trailing, AxiomSpacing.sm)
            .offset(y: yOffset - 8)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                currentTime = Date()
            }
        }
    }
}
