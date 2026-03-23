import SwiftUI
import SwiftData

struct DayTimelineView: View {
    let events: [CalendarEvent]
    let hourHeight: CGFloat
    let onEventTap: (CalendarEvent) -> Void
    let onEventReschedule: (CalendarEvent, CGFloat) -> Void

    @State private var draggedEvent: CalendarEvent?
    @State private var dragOffset: CGFloat = 0
    @State private var availableWidth: CGFloat = 300

    private var totalHeight: CGFloat { hourHeight * 24 }

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid lines and labels
                        HourGridView(hourHeight: hourHeight)

                        // Event blocks
                        ForEach(positionedEvents, id: \.event.id) { positioned in
                            DayEventBlockView(
                                event: positioned.event,
                                isDragging: draggedEvent?.id == positioned.event.id
                            )
                            .frame(
                                width: positioned.width,
                                height: max(positioned.height, TimelineConstants.minimumBlockHeight)
                            )
                            .offset(x: positioned.x, y: positioned.y + (draggedEvent?.id == positioned.event.id ? dragOffset : 0))
                            .onTapGesture {
                                onEventTap(positioned.event)
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        draggedEvent = positioned.event
                                        dragOffset = value.translation.height
                                    }
                                    .onEnded { value in
                                        let newY = positioned.y + value.translation.height
                                        let newMinutes = (newY / hourHeight) * 60
                                        let snappedMinutes = round(newMinutes / 15) * 15
                                        onEventReschedule(positioned.event, snappedMinutes)
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                            draggedEvent = nil
                                            dragOffset = 0
                                        }
                                    }
                            )
                        }

                        // Now line
                        NowLineView(hourHeight: hourHeight)
                    }
                    .frame(height: totalHeight)
                    .id("timeline")
                }
                .onAppear {
                    availableWidth = geo.size.width - TimelineConstants.hourLabelWidth - 16
                    scrollToNow(proxy: proxy)
                }
            }
        }
    }

    private var positionedEvents: [PositionedEvent] {
        DayTimelineLayout.layout(
            events: events,
            hourHeight: hourHeight,
            availableWidth: availableWidth
        )
    }

    private func scrollToNow(proxy: ScrollViewProxy) {
        // Auto-scroll handled by parent
    }
}

struct PositionedEvent {
    let event: CalendarEvent
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}
