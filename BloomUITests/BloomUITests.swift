//
//  BloomUITests.swift
//  BloomUITests
//
//  Island interaction flows: tap the island → the expanded layout appears;
//  tap outside → it collapses. The app is launched with --island-uitests,
//  which freezes ambient wallpaper animation so quiescence stays fast.
//

import CoreGraphics
import XCTest

final class BloomUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--island-uitests"]
        app.launch()
        return app
    }

    /// Taps an element, falling back to a center-coordinate tap for
    /// accessibility containers that report themselves as non-hittable.
    @MainActor
    private func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    @MainActor
    private func element(_ app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Taps the island. The pill itself sits inside the simulator's
    /// status-bar strip where synthesized touches never reach the app, so
    /// this taps the island's touch-grace zone just below the pill
    /// (top-center, 70 pt down) — still the island's own hit target.
    @MainActor
    private func tapIsland(_ app: XCUIApplication) {
        let island = element(app, identifier: "DynamicIsland")
        XCTAssertTrue(island.waitForExistence(timeout: 10), "The island should be mounted at launch")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 0, dy: 70))
            .tap()
    }

    // MARK: Tests

    @MainActor
    func testTappingIslandExpandsLiveActivity() throws {
        let app = launchApp()

        tapIsland(app)

        XCTAssertTrue(
            app.staticTexts["Golden Hour"].waitForExistence(timeout: 8),
            "Tapping the compact island should expand the music live activity"
        )
        XCTAssertTrue(
            app.staticTexts["Sable Rivers"].exists,
            "The expanded card should show the activity subtitle"
        )
    }

    @MainActor
    func testTappingOutsideCollapsesIsland() throws {
        let app = launchApp()

        tapIsland(app)
        let title = app.staticTexts["Golden Hour"]
        XCTAssertTrue(title.waitForExistence(timeout: 8), "The island should be expanded before collapsing")

        tapElement(element(app, identifier: "IslandCanvas"))

        XCTAssertTrue(
            title.waitForNonExistence(timeout: 5),
            "Tapping outside the island should collapse it back to the pill"
        )
    }

    @MainActor
    func testControlStripReachesTimerActivity() throws {
        let app = launchApp()

        let timerChip = app.buttons["ControlTimer"]
        XCTAssertTrue(timerChip.waitForExistence(timeout: 10), "The demo control strip should be visible")

        timerChip.tap()

        XCTAssertTrue(
            app.staticTexts["Focus Timer"].waitForExistence(timeout: 5),
            "The timer live activity should be reachable from the demo controls"
        )
    }

    @MainActor
    func testControlStripReachesActionBarAndOutsideTapDismissesIt() throws {
        let app = launchApp()

        let actionsChip = app.buttons["ControlActions"]
        XCTAssertTrue(actionsChip.waitForExistence(timeout: 10))

        actionsChip.tap()

        let reply = app.buttons["Reply"]
        XCTAssertTrue(
            reply.waitForExistence(timeout: 5),
            "The actions state should bloom into a glass action bar with a prominent Reply"
        )
        XCTAssertTrue(app.buttons["Love"].exists)
        XCTAssertTrue(app.buttons["More"].exists)

        tapElement(element(app, identifier: "IslandCanvas"))

        XCTAssertTrue(
            reply.waitForNonExistence(timeout: 5),
            "Tapping outside the action bar should collapse the island"
        )
    }
}
