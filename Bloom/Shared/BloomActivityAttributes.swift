//
//  BloomActivityAttributes.swift
//  Bloom
//
//  ActivityKit attributes for the island's live activities: pure data plus
//  date-driven rendering math. This file is written to be shared verbatim
//  with the future BloomIslandWidgets extension target (PR C of the
//  ActivityKit lift plan) — it must import only Foundation and ActivityKit,
//  and must not reference the in-app demo model or any UI.
//

import ActivityKit
import Foundation

/// One attributes type covers both sample activities; `kind` selects the
/// island layout, mirroring the in-app `LiveActivity` regions.
struct BloomActivityAttributes: ActivityAttributes {

    enum Kind: String, Codable, Hashable {
        case music
        case timer
    }

    struct ContentState: Codable, Hashable {
        /// The live payload for the activity's kind. An enum keeps
        /// music-only and timer-only fields from mixing.
        enum Payload: Codable, Hashable {
            /// A looping song that started playing at `songStart`.
            case music(songStart: Date, duration: TimeInterval)
            /// A countdown running over `range`.
            case timer(range: ClosedRange<Date>)
        }

        var payload: Payload
    }

    /// Which island layout this activity renders.
    var kind: Kind
    /// Center region title (song name / timer name).
    var title: String
    /// Center region subtitle (artist / session label).
    var subtitle: String
    /// SF Symbol for the leading region and the compact leading slot.
    var leadingSymbol: String
    /// SF Symbol for the trailing affordance (waveform / pause).
    var trailingSymbol: String
}

// MARK: - Content state factories

extension BloomActivityAttributes.ContentState {

    /// A countdown ending `duration` seconds after `start`.
    /// Negative durations clamp to an empty (already-finished) countdown.
    static func timer(start: Date, duration: TimeInterval) -> Self {
        let end = start.addingTimeInterval(max(0, duration))
        return Self(payload: .timer(range: start...end))
    }

    /// A looping song that started playing at `start`.
    static func music(start: Date, duration: TimeInterval) -> Self {
        Self(payload: .music(songStart: start, duration: duration))
    }
}

// MARK: - Widget-side rendering math

/// Date-pure helpers the widget layouts render from. The semantics
/// deliberately match `IslandViewModel`'s demo clocks — that parity is
/// unit-tested — so the system island and the in-app island always agree.
extension BloomActivityAttributes.ContentState {

    /// The countdown interval, if this is a timer payload. Feed directly to
    /// `Text(timerInterval:countsDown:)` / `ProgressView(timerInterval:)`.
    var timerRange: ClosedRange<Date>? {
        if case .timer(let range) = payload { return range }
        return nil
    }

    /// Seconds left on the countdown at `date`, clamped to 0…duration.
    /// `nil` for non-timer payloads.
    func timerRemaining(at date: Date) -> TimeInterval? {
        guard let range = timerRange else { return nil }
        let duration = range.upperBound.timeIntervalSince(range.lowerBound)
        return min(max(0, range.upperBound.timeIntervalSince(date)), duration)
    }

    /// Fraction of the countdown remaining at `date`, in 0…1.
    /// `nil` for non-timer payloads.
    func timerFraction(at date: Date) -> Double? {
        guard let range = timerRange else { return nil }
        let duration = range.upperBound.timeIntervalSince(range.lowerBound)
        guard duration > 0 else { return 0 }
        let remaining = min(max(0, range.upperBound.timeIntervalSince(date)), duration)
        return remaining / duration
    }

    /// Seconds into the looping song at `date`, in 0…<duration.
    /// `nil` for non-music payloads.
    func musicElapsed(at date: Date) -> TimeInterval? {
        guard case .music(let songStart, let duration) = payload else { return nil }
        guard duration > 0 else { return 0 }
        let raw = date.timeIntervalSince(songStart)
            .truncatingRemainder(dividingBy: duration)
        return raw < 0 ? raw + duration : raw
    }

    /// Playback progress of the looping song at `date`, in 0…1.
    /// `nil` for non-music payloads.
    func musicProgress(at date: Date) -> Double? {
        guard case .music(_, let duration) = payload else { return nil }
        guard duration > 0 else { return 0 }
        guard let elapsed = musicElapsed(at: date) else { return nil }
        return elapsed / duration
    }
}
