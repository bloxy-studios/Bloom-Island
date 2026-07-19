//
//  ActivityLift.swift
//  Bloom
//
//  Bridges the in-app demo island (LiveActivity + IslandViewModel clocks)
//  into ActivityKit attributes and content. App-side only: the widget
//  target never needs the demo model, so when PR C adds the extension this
//  file stays out of its membership.
//

import Foundation

extension BloomActivityAttributes.Kind {

    /// The demo model's kind, lifted unchanged.
    init(lifting kind: LiveActivity.Kind) {
        switch kind {
        case .music: self = .music
        case .timer: self = .timer
        }
    }
}

extension BloomActivityAttributes {

    /// Lifts the demo activity's static regions into ActivityKit attributes
    /// unchanged — the same title, subtitle and symbols the island renders.
    init(lifting activity: LiveActivity) {
        self.init(
            kind: Kind(lifting: activity.kind),
            title: activity.title,
            subtitle: activity.subtitle,
            leadingSymbol: activity.leadingSymbol,
            trailingSymbol: activity.trailingSymbol
        )
    }
}

extension IslandViewModel {

    /// A snapshot of the demo clocks as ActivityKit content for `activity`.
    ///
    /// The timer's start is reconstructed as `end − duration`, which is
    /// exact by construction: both `init` and `restartTimer` derive the end
    /// date as `now + duration`.
    func liftedContentState(for activity: LiveActivity) -> BloomActivityAttributes.ContentState {
        switch activity.kind {
        case .music:
            return .music(start: musicStartDate, duration: musicDuration)
        case .timer:
            return .timer(
                start: timerEndDate.addingTimeInterval(-timerDuration),
                duration: timerDuration
            )
        }
    }

    /// Attributes plus the initial content state, ready for
    /// `Activity.request(attributes:content:)` when PR C wires it up.
    func liftedActivity(
        for activity: LiveActivity
    ) -> (attributes: BloomActivityAttributes, state: BloomActivityAttributes.ContentState) {
        (BloomActivityAttributes(lifting: activity), liftedContentState(for: activity))
    }
}
