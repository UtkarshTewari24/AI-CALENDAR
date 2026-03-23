import SwiftUI

struct HourGridView: View {
    let hourHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    // Hour label
                    Text(hourLabel(for: hour))
                        .font(AxiomTypography.micro)
                        .foregroundStyle(AxiomColors.textSecondary)
                        .frame(width: TimelineConstants.hourLabelWidth, alignment: .trailing)
                        .padding(.trailing, AxiomSpacing.sm)
                        .offset(y: -6)

                    // Grid line
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(AxiomColors.surface.opacity(0.5))
                            .frame(height: 0.5)
                        Spacer()
                    }
                }
                .frame(height: hourHeight)
            }
        }
    }

    private func hourLabel(for hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}
