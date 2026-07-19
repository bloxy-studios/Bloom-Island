//
//  BloomTests.swift
//  BloomTests
//
//  State-machine transitions and per-state geometry for the Dynamic Island,
//  plus the demo activity clocks — all pure values, no UI required.
//

import CoreGraphics
import Foundation
import Testing
@testable import Bloom

private func approximately(_ value: CGFloat, _ expected: CGFloat, tolerance: CGFloat = 0.001) -> Bool {
    abs(value - expected) <= tolerance
}

// MARK: - State machine

@MainActor
struct IslandStateMachineTests {

    @Test func initialStateIsCompact() {
        let model = IslandViewModel()
        #expect(model.state == .compact)
        #expect(model.state.isExpanded == false)
        #expect(model.selectedActivity == .music)
    }

    @Test func tapFromCompactExpandsToSelectedActivity() {
        let model = IslandViewModel()
        model.tapIsland()
        #expect(model.state == .live(.music))
        #expect(model.state.isExpanded)
    }

    @Test func tapFromLiveBloomsIntoActions() {
        let model = IslandViewModel()
        model.show(.timer)
        model.tapIsland()
        #expect(model.state == .actions)
    }

    @Test func tapFromActionsIsAbsorbedByTheBar() {
        let model = IslandViewModel()
        model.showActions()
        model.tapIsland()
        #expect(model.state == .actions)
    }

    @Test func showSetsLiveStateAndSelection() {
        let model = IslandViewModel()
        model.show(.timer)
        #expect(model.state == .live(.timer))
        #expect(model.selectedActivity == .timer)

        model.show(.music)
        #expect(model.state == .live(.music))
        #expect(model.selectedActivity == .music)
    }

    @Test func selectionSurvivesCollapse() {
        let model = IslandViewModel()
        model.show(.timer)
        model.collapse()
        #expect(model.state == .compact)
        #expect(model.selectedActivity == .timer)

        model.tapIsland()
        #expect(model.state == .live(.timer))
    }

    @Test func collapseReturnsToCompactFromAnyState() {
        let fromLive = IslandViewModel(state: .live(.music))
        fromLive.collapse()
        #expect(fromLive.state == .compact)

        let fromActions = IslandViewModel(state: .actions)
        fromActions.collapse()
        #expect(fromActions.state == .compact)
    }

    @Test func tapOutsideCollapses() {
        let model = IslandViewModel()
        model.showActions()
        model.tapOutside()
        #expect(model.state == .compact)
    }

    @Test func initializingWithLiveStateSyncsSelection() {
        let model = IslandViewModel(state: .live(.timer))
        #expect(model.selectedActivity == .timer)
        #expect(model.state.activity == .timer)
    }

    @Test func expansionFlags() {
        #expect(IslandState.compact.isExpanded == false)
        #expect(IslandState.live(.music).isExpanded)
        #expect(IslandState.live(.timer).isExpanded)
        #expect(IslandState.actions.isExpanded)
        #expect(IslandState.compact.activity == nil)
        #expect(IslandState.actions.activity == nil)
    }
}

// MARK: - Geometry

@MainActor
struct IslandGeometryTests {

    /// iPhone 17 Pro class portrait width.
    private let containerWidth: CGFloat = 402

    @Test func compactMatchesTheSensorHousing() {
        let geometry = IslandState.compact.geometry(in: containerWidth)
        #expect(approximately(geometry.width, 126))
        #expect(approximately(geometry.height, 37.3))
        #expect(approximately(geometry.cornerRadius, 37.3 / 2))
        #expect(approximately(geometry.topInset, 11))
    }

    @Test func compactGeometryIgnoresContainerWidth() {
        let narrow = IslandState.compact.geometry(in: 320)
        let wide = IslandState.compact.geometry(in: 1024)
        #expect(narrow == wide)
    }

    @Test func liveGeometryFillsWidthMinusMargin() {
        let geometry = IslandState.live(.music).geometry(in: containerWidth)
        #expect(approximately(geometry.width, containerWidth - 28))
        #expect(approximately(geometry.cornerRadius, 44))
        #expect(approximately(geometry.topInset, 11))
    }

    @Test func liveHeightsStayWithinTheBriefCap() {
        let music = IslandState.live(.music).geometry(in: containerWidth)
        let timer = IslandState.live(.timer).geometry(in: containerWidth)
        #expect(approximately(music.height, 160))
        #expect(music.height <= 160)
        #expect(approximately(timer.height, 136))
        #expect(timer.height <= 160)
    }

    @Test func actionsGeometryIsACapsuleBar() {
        let geometry = IslandState.actions.geometry(in: containerWidth)
        #expect(approximately(geometry.width, containerWidth - 28))
        #expect(approximately(geometry.height, 64))
        #expect(approximately(geometry.cornerRadius, 32))
        #expect(approximately(geometry.topInset, 11))
    }

    @Test func expandedWidthNeverDropsBelowTheCompactPill() {
        let geometry = IslandState.live(.music).geometry(in: 100)
        #expect(approximately(geometry.width, 126))
    }

    @Test func topInsetIsStableAcrossStates() {
        for state in [IslandState.compact, .live(.music), .live(.timer), .actions] {
            #expect(approximately(state.geometry(in: containerWidth).topInset, 11))
        }
    }

    @Test func geometrySizeMirrorsWidthAndHeight() {
        let geometry = IslandState.live(.timer).geometry(in: containerWidth)
        #expect(geometry.size == CGSize(width: geometry.width, height: geometry.height))
    }
}

// MARK: - Demo activity clocks

@MainActor
struct IslandDemoDataTests {

    private let epoch = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test func timerCountsDownAndClamps() {
        let model = IslandViewModel(now: epoch)
        #expect(abs(model.timerRemaining(at: epoch) - 15 * 60) < 0.001)
        #expect(abs(model.timerRemaining(at: epoch.addingTimeInterval(60)) - 14 * 60) < 0.001)
        #expect(model.timerRemaining(at: epoch.addingTimeInterval(16 * 60)) == 0)
        // Before the reference clock, remaining clamps to the full duration.
        #expect(abs(model.timerRemaining(at: epoch.addingTimeInterval(-99)) - 15 * 60) < 0.001)
    }

    @Test func timerFractionIsUnitClamped() {
        let model = IslandViewModel(now: epoch)
        #expect(abs(model.timerFraction(at: epoch) - 1) < 0.001)
        #expect(abs(model.timerFraction(at: epoch.addingTimeInterval(7.5 * 60)) - 0.5) < 0.001)
        #expect(model.timerFraction(at: epoch.addingTimeInterval(20 * 60)) == 0)
    }

    @Test func restartTimerRebasesTheCountdown() {
        let model = IslandViewModel(now: epoch)
        model.restartTimer(duration: 5 * 60, from: epoch)
        #expect(abs(model.timerRemaining(at: epoch) - 5 * 60) < 0.001)
        #expect(abs(model.timerRemaining(at: epoch.addingTimeInterval(60)) - 4 * 60) < 0.001)
    }

    @Test func musicProgressLoopsWithinUnitRange() {
        let model = IslandViewModel(now: epoch)
        #expect(model.musicProgress(at: epoch) == 0)

        let half = model.musicDuration / 2
        #expect(abs(model.musicProgress(at: epoch.addingTimeInterval(half)) - 0.5) < 0.001)

        // Past the end of the song, playback wraps around.
        let wrapped = model.musicElapsed(at: epoch.addingTimeInterval(model.musicDuration + 10))
        #expect(abs(wrapped - 10) < 0.001)

        for offset in [0.0, 42, 500, 5000] {
            let progress = model.musicProgress(at: epoch.addingTimeInterval(offset))
            #expect(progress >= 0 && progress < 1)
        }
    }

    @Test func countdownFormatting() {
        #expect(IslandViewModel.formattedCountdown(754) == "12:34")
        #expect(IslandViewModel.formattedCountdown(0) == "0:00")
        #expect(IslandViewModel.formattedCountdown(59) == "0:59")
        #expect(IslandViewModel.formattedCountdown(60) == "1:00")
        #expect(IslandViewModel.formattedCountdown(15 * 60) == "15:00")
        #expect(IslandViewModel.formattedCountdown(-5) == "0:00")
    }

    @Test func sampleActivitiesArePopulatedAndDistinct() {
        #expect(LiveActivity.music.kind == .music)
        #expect(LiveActivity.timer.kind == .timer)
        #expect(LiveActivity.music.id != LiveActivity.timer.id)

        for activity in [LiveActivity.music, LiveActivity.timer] {
            #expect(!activity.title.isEmpty)
            #expect(!activity.subtitle.isEmpty)
            #expect(!activity.leadingSymbol.isEmpty)
            #expect(!activity.trailingSymbol.isEmpty)
        }
    }
}
