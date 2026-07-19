//
//  IslandViewModel.swift
//  Bloom
//
//  Observable driver for the island: state transitions plus demo
//  live-activity data expressed as pure functions of a date, so the
//  UI can render from any clock and tests can pin time.
//

import Foundation
import Observation

@Observable
final class IslandViewModel {

    // MARK: State

    /// Current island state. Mutate via the transition methods below.
    private(set) var state: IslandState

    /// The activity the island expands to when tapped from compact.
    private(set) var selectedActivity: LiveActivity

    /// Demo wallpaper hue shift (0…1) — proves the glass responds to what's behind it.
    var wallpaperShift: Double = 0

    // MARK: Demo activity data

    /// Total duration of the demo countdown.
    private(set) var timerDuration: TimeInterval
    /// Instant the demo countdown reaches zero.
    private(set) var timerEndDate: Date
    /// Total duration of the demo song.
    private(set) var musicDuration: TimeInterval
    /// Instant the demo song "started" playing.
    private(set) var musicStartDate: Date

    // MARK: Init

    init(state: IslandState = .compact, now: Date = Date()) {
        self.state = state
        self.selectedActivity = state.activity ?? .music
        self.timerDuration = 15 * 60
        self.timerEndDate = now.addingTimeInterval(15 * 60)
        self.musicDuration = 3 * 60 + 42
        self.musicStartDate = now
    }

    // MARK: Transitions

    /// A tap on the island body: the pill opens into its activity, an open
    /// activity blooms into the action bar, and the action bar absorbs the
    /// tap (its buttons own their own hits).
    func tapIsland() {
        switch state {
        case .compact:
            state = .live(selectedActivity)
        case .live:
            state = .actions
        case .actions:
            break
        }
    }

    /// Expands the island to the given activity from any state.
    func show(_ activity: LiveActivity) {
        selectedActivity = activity
        state = .live(activity)
    }

    /// Blooms the island into the glass action bar from any state.
    func showActions() {
        state = .actions
    }

    /// Returns the island to the hardware pill from any state.
    func collapse() {
        state = .compact
    }

    /// A tap anywhere outside the island collapses it.
    func tapOutside() {
        collapse()
    }

    // MARK: Timer demo data (pure functions of a date)

    /// Seconds left on the demo countdown at `date`, clamped to 0…duration.
    func timerRemaining(at date: Date) -> TimeInterval {
        min(max(0, timerEndDate.timeIntervalSince(date)), timerDuration)
    }

    /// Fraction of the countdown remaining at `date`, in 0…1.
    func timerFraction(at date: Date) -> Double {
        guard timerDuration > 0 else { return 0 }
        return timerRemaining(at: date) / timerDuration
    }

    /// Restarts the demo countdown so it ends `duration` seconds after `from`.
    func restartTimer(duration: TimeInterval, from now: Date = Date()) {
        timerDuration = max(0, duration)
        timerEndDate = now.addingTimeInterval(timerDuration)
    }

    // MARK: Music demo data (pure functions of a date)

    /// Seconds into the looping demo song at `date`, in 0…<duration.
    func musicElapsed(at date: Date) -> TimeInterval {
        guard musicDuration > 0 else { return 0 }
        let raw = date.timeIntervalSince(musicStartDate)
            .truncatingRemainder(dividingBy: musicDuration)
        return raw < 0 ? raw + musicDuration : raw
    }

    /// Playback progress of the looping demo song at `date`, in 0…1.
    func musicProgress(at date: Date) -> Double {
        guard musicDuration > 0 else { return 0 }
        return musicElapsed(at: date) / musicDuration
    }

    // MARK: Formatting

    /// Formats a number of seconds as `m:ss` (e.g. 754 → "12:34").
    static func formattedCountdown(_ seconds: TimeInterval) -> String {
        let whole = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }
}
