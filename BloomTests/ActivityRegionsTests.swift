//
//  ActivityRegionsTests.swift
//  BloomTests
//
//  PR B of the ActivityKit lift plan: the shared region layer must agree
//  with the app-side tokens and formatters it replaced, so the in-app
//  island stays pixel-identical and the widget can never drift.
//

import Foundation
import SwiftUI
import Testing
@testable import Bloom

@MainActor
struct ActivityRegionsTests {

    // MARK: Formatting delegation

    @Test func countdownFormatterStaysExactThroughDelegation() {
        let samples: [TimeInterval] = [0, 1, 59, 60, 61, 754, 900, 3599, 3600, -5]
        for seconds in samples {
            #expect(ActivityFormat.countdown(seconds) == IslandViewModel.formattedCountdown(seconds))
        }
        #expect(ActivityFormat.countdown(754) == "12:34")
        #expect(ActivityFormat.countdown(0) == "0:00")
        #expect(ActivityFormat.countdown(-5) == "0:00")
    }

    // MARK: Accent parity

    @Test func glassTokensAccentsDelegateToTheSharedKindAccent() {
        #expect(GlassTokens.accent(for: .music) == BloomActivityAttributes.Kind.music.accent)
        #expect(GlassTokens.accent(for: .timer) == BloomActivityAttributes.Kind.timer.accent)
    }

    @Test func accentsAreDistinctPerKind() {
        #expect(BloomActivityAttributes.Kind.music.accent != BloomActivityAttributes.Kind.timer.accent)
    }

    @Test func sharedPaletteMirrorsTheGlassTokens() {
        #expect(ActivityPalette.artworkShadow == GlassTokens.deepMauve)
    }
}
