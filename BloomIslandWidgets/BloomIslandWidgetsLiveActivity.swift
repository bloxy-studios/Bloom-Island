//
//  BloomIslandWidgetsLiveActivity.swift
//  BloomIslandWidgets
//
//  The system Live Activity for Bloom's island: the Lock Screen banner and
//  the real Dynamic Island presentations, rendered from the same shared
//  regions the in-app island uses (Shared/ActivityRegions.swift) and the
//  same BloomActivityAttributes the app requests with. The in-app island
//  was the design playground; this is the production surface it was
//  designed to lift into.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct BloomIslandWidgetsLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BloomActivityAttributes.self) { context in
            // Lock Screen / banner: the full shared card on island black.
            ActivityCardView(
                attributes: context.attributes,
                content: context.state,
                renderingContext: .widget
            )
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let card = ActivityCardView(
                attributes: context.attributes,
                content: context.state,
                renderingContext: .widget
            )
            let accent = context.attributes.kind.accent

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    card.leadingRegion
                }
                DynamicIslandExpandedRegion(.center) {
                    card.centerRegion
                }
                DynamicIslandExpandedRegion(.trailing) {
                    card.trailingRegion
                }
                DynamicIslandExpandedRegion(.bottom) {
                    card.bottomRegion
                }
            } compactLeading: {
                Image(systemName: context.attributes.leadingSymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            } compactTrailing: {
                CompactTrailingSlot(
                    attributes: context.attributes,
                    content: context.state
                )
            } minimal: {
                Image(systemName: context.attributes.leadingSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .keylineTint(accent)
        }
    }
}

/// The compact trailing slot: a static waveform for music, the
/// system-driven countdown for timers.
private struct CompactTrailingSlot: View {
    let attributes: BloomActivityAttributes
    let content: BloomActivityAttributes.ContentState

    var body: some View {
        switch attributes.kind {
        case .music:
            WaveformGlyph(tint: attributes.kind.accent, animated: false)
        case .timer:
            if let range = content.timerRange {
                Text(timerInterval: range, countsDown: true)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 44)
                    .foregroundStyle(attributes.kind.accent)
            }
        }
    }
}

// MARK: - Previews

extension BloomActivityAttributes {

    fileprivate static var previewMusic: BloomActivityAttributes {
        BloomActivityAttributes(
            kind: .music,
            title: "Golden Hour",
            subtitle: "Sable Rivers",
            leadingSymbol: "music.note",
            trailingSymbol: "waveform"
        )
    }

    fileprivate static var previewTimer: BloomActivityAttributes {
        BloomActivityAttributes(
            kind: .timer,
            title: "Focus Timer",
            subtitle: "Deep work",
            leadingSymbol: "timer",
            trailingSymbol: "pause.fill"
        )
    }
}

#Preview("Lock Screen — Music", as: .content, using: BloomActivityAttributes.previewMusic) {
    BloomIslandWidgetsLiveActivity()
} contentStates: {
    BloomActivityAttributes.ContentState.music(start: .now, duration: 222)
}

#Preview("Island expanded — Music", as: .dynamicIsland(.expanded), using: BloomActivityAttributes.previewMusic) {
    BloomIslandWidgetsLiveActivity()
} contentStates: {
    BloomActivityAttributes.ContentState.music(start: .now, duration: 222)
}

#Preview("Island expanded — Timer", as: .dynamicIsland(.expanded), using: BloomActivityAttributes.previewTimer) {
    BloomIslandWidgetsLiveActivity()
} contentStates: {
    BloomActivityAttributes.ContentState.timer(start: .now, duration: 15 * 60)
}

#Preview("Island compact — Timer", as: .dynamicIsland(.compact), using: BloomActivityAttributes.previewTimer) {
    BloomIslandWidgetsLiveActivity()
} contentStates: {
    BloomActivityAttributes.ContentState.timer(start: .now, duration: 15 * 60)
}

#Preview("Island minimal — Music", as: .dynamicIsland(.minimal), using: BloomActivityAttributes.previewMusic) {
    BloomIslandWidgetsLiveActivity()
} contentStates: {
    BloomActivityAttributes.ContentState.music(start: .now, duration: 222)
}
