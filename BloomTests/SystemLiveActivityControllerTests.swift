//
//  SystemLiveActivityControllerTests.swift
//  BloomTests
//
//  PR C: the demo's ActivityKit plumbing, tested up to the ActivityKit
//  boundary only — no Activity.request calls from unit tests (the request
//  path is exercised manually in the simulator per the lift plan).
//

import Foundation
import Testing
@testable import Bloom

@MainActor
struct SystemLiveActivityControllerTests {

    @Test func initialStateIsIdle() {
        let controller = SystemLiveActivityController()
        #expect(controller.isRunning == false)
        #expect(controller.statusMessage == nil)
    }

    @Test func endingWithoutAnActivityIsSafe() {
        let controller = SystemLiveActivityController()
        controller.end()
        #expect(controller.isRunning == false)
        #expect(controller.statusMessage == nil)
    }

    @Test func liftedRequestPayloadMatchesTheIslandSelection() {
        // The exact pairing the controller hands to Activity.request.
        let epoch = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let model = IslandViewModel(now: epoch)
        model.show(.timer)

        let lifted = model.liftedActivity(for: model.selectedActivity)
        #expect(lifted.attributes.kind == .timer)
        #expect(lifted.attributes.title == LiveActivity.timer.title)
        #expect(lifted.state.timerRange == epoch...epoch.addingTimeInterval(15 * 60))
    }
}
