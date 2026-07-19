//
//  IslandState.swift
//  Bloom
//
//  The island's single source of truth: state enum, sample live-activity
//  content, and per-state geometry as pure values (unit-testable without UI).
//

import CoreGraphics
import Foundation

// MARK: - Live activity content

/// A sample live activity rendered by the island's expanded state.
///
/// The regions deliberately mirror ActivityKit's expanded layout regions
/// (leading / center / trailing / bottom) so this design can later be lifted
/// into a real ActivityKit widget unchanged.
struct LiveActivity: Equatable, Identifiable {

    enum Kind: String, CaseIterable {
        case music
        case timer
    }

    let kind: Kind

    /// SF Symbol shown in the compact leading slot and expanded leading region.
    let leadingSymbol: String
    /// Title line of the expanded center region.
    let title: String
    /// Subtitle line of the expanded center region.
    let subtitle: String
    /// SF Symbol used by the expanded trailing region (music) or compact trailing slot.
    let trailingSymbol: String

    var id: String { kind.rawValue }

    /// Sample "Now Playing" activity.
    static let music = LiveActivity(
        kind: .music,
        leadingSymbol: "music.note",
        title: "Golden Hour",
        subtitle: "Sable Rivers",
        trailingSymbol: "waveform"
    )

    /// Sample countdown timer activity.
    static let timer = LiveActivity(
        kind: .timer,
        leadingSymbol: "timer",
        title: "Focus Timer",
        subtitle: "Deep work",
        trailingSymbol: "pause.fill"
    )
}

// MARK: - Island state

/// The three visual states of the in-app Dynamic Island.
enum IslandState: Equatable {
    /// The hardware pill sitting over the sensor housing.
    case compact
    /// An expanded Live Activity card for the given activity.
    case live(LiveActivity)
    /// The island bloomed into a row of glass action buttons.
    case actions

    /// Whether the island is showing anything beyond the hardware pill.
    var isExpanded: Bool {
        switch self {
        case .compact: false
        case .live, .actions: true
        }
    }

    /// The activity displayed by this state, if any.
    var activity: LiveActivity? {
        if case .live(let activity) = self { return activity }
        return nil
    }
}

// MARK: - Geometry

/// Resolved geometry for one island state. Pure values — no view code.
struct IslandGeometry: Equatable {
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat
    var topInset: CGFloat

    var size: CGSize { CGSize(width: width, height: height) }
}

extension IslandState {

    /// Hardware pill metrics for the iPhone Pro class sensor housing.
    enum Metrics {
        /// Collapsed pill width, matching the sensor housing.
        static let compactWidth: CGFloat = 126
        /// Collapsed pill height, matching the sensor housing.
        static let compactHeight: CGFloat = 37.3
        /// Distance from the true top of the screen to the island.
        static let topInset: CGFloat = 11
        /// Horizontal margin consumed by expanded states (14 pt per side).
        static let expandedHorizontalMargin: CGFloat = 28
        /// Continuous corner radius of expanded live-activity cards.
        static let expandedCornerRadius: CGFloat = 44
        /// Height of the music live-activity card (≤ 160 per the brief).
        static let musicCardHeight: CGFloat = 160
        /// Height of the timer live-activity card.
        static let timerCardHeight: CGFloat = 136
        /// Height of the glass action bar.
        static let actionBarHeight: CGFloat = 64
    }

    /// Resolves the island's frame for this state inside a container of the
    /// given width. The expanded width is `containerWidth − 28`, floored at
    /// the compact width so degenerate containers never invert the pill.
    func geometry(in containerWidth: CGFloat) -> IslandGeometry {
        let expandedWidth = max(
            Metrics.compactWidth,
            containerWidth - Metrics.expandedHorizontalMargin
        )

        switch self {
        case .compact:
            return IslandGeometry(
                width: Metrics.compactWidth,
                height: Metrics.compactHeight,
                cornerRadius: Metrics.compactHeight / 2,
                topInset: Metrics.topInset
            )

        case .live(let activity):
            let height: CGFloat
            switch activity.kind {
            case .music: height = Metrics.musicCardHeight
            case .timer: height = Metrics.timerCardHeight
            }
            return IslandGeometry(
                width: expandedWidth,
                height: height,
                cornerRadius: Metrics.expandedCornerRadius,
                topInset: Metrics.topInset
            )

        case .actions:
            return IslandGeometry(
                width: expandedWidth,
                height: Metrics.actionBarHeight,
                cornerRadius: Metrics.actionBarHeight / 2,
                topInset: Metrics.topInset
            )
        }
    }
}
