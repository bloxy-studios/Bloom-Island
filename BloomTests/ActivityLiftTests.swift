//
//  ActivityLiftTests.swift
//  BloomTests
//
//  PR A of the ActivityKit lift plan: the shared attributes/content model
//  must carry the demo island's regions unchanged, and its date-pure
//  rendering math must agree exactly with IslandViewModel's clocks.
//

import Foundation
import Testing
@testable import Bloom

private func closeEnough(_ a: TimeInterval?, _ b: TimeInterval, tolerance: Double = 1e-9) -> Bool {
    guard let a else { return false }
    return abs(a - b) <= tolerance
}

@MainActor
struct ActivityLiftTests {

    private let epoch = Date(timeIntervalSinceReferenceDate: 800_000_000)

    // MARK: Attributes

    @Test func attributesLiftStaticRegionsUnchanged() {
        for demo in [LiveActivity.music, LiveActivity.timer] {
            let attributes = BloomActivityAttributes(lifting: demo)
            #expect(attributes.kind.rawValue == demo.kind.rawValue)
            #expect(attributes.title == demo.title)
            #expect(attributes.subtitle == demo.subtitle)
            #expect(attributes.leadingSymbol == demo.leadingSymbol)
            #expect(attributes.trailingSymbol == demo.trailingSymbol)
        }
    }

    @Test func kindLiftCoversEveryDemoKind() {
        for kind in LiveActivity.Kind.allCases {
            #expect(BloomActivityAttributes.Kind(lifting: kind).rawValue == kind.rawValue)
        }
    }

    // MARK: Timer parity with the demo clock

    @Test func timerContentStateSpansTheDemoCountdown() {
        let model = IslandViewModel(now: epoch)
        let state = model.liftedContentState(for: .timer)
        #expect(state.timerRange == epoch...epoch.addingTimeInterval(15 * 60))
    }

    @Test func timerMathMatchesTheViewModel() {
        let model = IslandViewModel(now: epoch)
        let state = model.liftedContentState(for: .timer)

        for offset in [0.0, 1, 60, 7.5 * 60, 15 * 60, 16 * 60, -99] {
            let date = epoch.addingTimeInterval(offset)
            #expect(closeEnough(state.timerRemaining(at: date), model.timerRemaining(at: date)))
            #expect(closeEnough(state.timerFraction(at: date), model.timerFraction(at: date)))
        }
    }

    @Test func timerMathMatchesAfterRestart() {
        let model = IslandViewModel(now: epoch)
        model.restartTimer(duration: 5 * 60, from: epoch.addingTimeInterval(30))
        let state = model.liftedContentState(for: .timer)

        for offset in [30.0, 90, 30 + 5 * 60, 1000] {
            let date = epoch.addingTimeInterval(offset)
            #expect(closeEnough(state.timerRemaining(at: date), model.timerRemaining(at: date)))
            #expect(closeEnough(state.timerFraction(at: date), model.timerFraction(at: date)))
        }
    }

    // MARK: Music parity with the demo clock

    @Test func musicMathMatchesTheViewModel() {
        let model = IslandViewModel(now: epoch)
        let state = model.liftedContentState(for: .music)

        for offset in [0.0, 42, model.musicDuration / 2, model.musicDuration + 10, 5000, -7] {
            let date = epoch.addingTimeInterval(offset)
            #expect(closeEnough(state.musicElapsed(at: date), model.musicElapsed(at: date)))
            #expect(closeEnough(state.musicProgress(at: date), model.musicProgress(at: date)))
        }
    }

    // MARK: Kind safety

    @Test func wrongKindAccessorsReturnNil() {
        let music = BloomActivityAttributes.ContentState.music(start: epoch, duration: 200)
        #expect(music.timerRange == nil)
        #expect(music.timerRemaining(at: epoch) == nil)
        #expect(music.timerFraction(at: epoch) == nil)

        let timer = BloomActivityAttributes.ContentState.timer(start: epoch, duration: 300)
        #expect(timer.musicElapsed(at: epoch) == nil)
        #expect(timer.musicProgress(at: epoch) == nil)
    }

    // MARK: Degenerate durations

    @Test func zeroAndNegativeDurationsAreSafe() {
        let zeroTimer = BloomActivityAttributes.ContentState.timer(start: epoch, duration: 0)
        #expect(zeroTimer.timerRange == epoch...epoch)
        #expect(closeEnough(zeroTimer.timerRemaining(at: epoch), 0))
        #expect(closeEnough(zeroTimer.timerFraction(at: epoch), 0))

        // A negative duration clamps to an already-finished countdown
        // instead of forming an invalid range.
        let negativeTimer = BloomActivityAttributes.ContentState.timer(start: epoch, duration: -60)
        #expect(negativeTimer.timerRange == epoch...epoch)

        let zeroMusic = BloomActivityAttributes.ContentState.music(start: epoch, duration: 0)
        #expect(closeEnough(zeroMusic.musicElapsed(at: epoch.addingTimeInterval(99)), 0))
        #expect(closeEnough(zeroMusic.musicProgress(at: epoch.addingTimeInterval(99)), 0))
    }

    // MARK: Codable round trips

    @Test func contentStateSurvivesCodableRoundTrip() throws {
        let states: [BloomActivityAttributes.ContentState] = [
            .music(start: epoch, duration: 222),
            .timer(start: epoch, duration: 15 * 60),
        ]
        for state in states {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(
                BloomActivityAttributes.ContentState.self,
                from: data
            )
            #expect(decoded == state)
        }
    }

    @Test func attributesSurviveCodableRoundTrip() throws {
        let attributes = BloomActivityAttributes(lifting: .music)
        let data = try JSONEncoder().encode(attributes)
        let decoded = try JSONDecoder().decode(BloomActivityAttributes.self, from: data)
        #expect(decoded.kind == attributes.kind)
        #expect(decoded.title == attributes.title)
        #expect(decoded.subtitle == attributes.subtitle)
        #expect(decoded.leadingSymbol == attributes.leadingSymbol)
        #expect(decoded.trailingSymbol == attributes.trailingSymbol)
    }

    // MARK: Request wiring

    @Test func liftedActivityPairsAttributesWithCurrentClocks() {
        let model = IslandViewModel(now: epoch)
        let lifted = model.liftedActivity(for: .timer)
        #expect(lifted.attributes.kind == .timer)
        #expect(lifted.attributes.title == LiveActivity.timer.title)
        #expect(lifted.state.timerRange == epoch...epoch.addingTimeInterval(15 * 60))
    }
}
