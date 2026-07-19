//
//  GlassTokens.swift
//  Bloom
//
//  One place for the island's glass recipes, tints, motion curves and the
//  demo wallpaper palette. Views never invent styling values locally.
//

import CoreGraphics
import SwiftUI

enum GlassTokens {

    // MARK: Motion

    /// Geometry morphs: springy, weighty, one soft bounce. Never linear.
    static let geometrySpring: Animation = .spring(response: 0.45, dampingFraction: 0.72)

    /// Content swaps ride a snappier curve than the surface they live on.
    static let contentSpring: Animation = .snappy

    /// Press stretch toward the touch.
    static let pressSpring: Animation = .spring(response: 0.3, dampingFraction: 0.6)

    /// Reduce Motion replaces springs with a quiet crossfade.
    static let reducedMotionFade: Animation = .easeOut(duration: 0.18)

    /// The morph animation for a state change, honoring Reduce Motion.
    static func stateChange(reduceMotion: Bool) -> Animation {
        reduceMotion ? reducedMotionFade : geometrySpring
    }

    /// How swapped content enters/leaves, honoring Reduce Motion.
    static func contentTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : AnyTransition(.blurReplace)
    }

    // MARK: Island surface

    /// The island body is near-black glass: opaque enough to read as
    /// hardware, open enough for the wallpaper to bleed through the rim.
    static let surfaceTint = Color.black.opacity(0.87)

    /// Solid replacement for the surface under Reduce Transparency.
    static let opaqueSurface = Color(red: 0.05, green: 0.045, blue: 0.06)

    /// Glass recipe for the island surface.
    static var surfaceGlass: Glass {
        .regular.tint(surfaceTint).interactive()
    }

    /// Container spacing at which neighboring glass begins to melt together.
    static let morphSpacing: CGFloat = 24

    // MARK: Action bar

    /// Spacing between action buttons (matched by the container so buttons
    /// stay separate at rest but merge mid-morph).
    static let actionSpacing: CGFloat = 12

    /// Tint of the prominent primary action.
    static let primaryActionTint = Color(red: 0.72, green: 0.42, blue: 0.62)

    // MARK: Accents

    /// Warm accent for the music activity.
    static let musicAccent = Color(red: 0.94, green: 0.72, blue: 0.44)

    /// Cool mauve accent for the timer activity.
    static let timerAccent = Color(red: 0.80, green: 0.62, blue: 0.86)

    static func accent(for activity: LiveActivity) -> Color {
        switch activity.kind {
        case .music: musicAccent
        case .timer: timerAccent
        }
    }

    // MARK: Lens lip

    /// The refractive lip at the island's lower edge picks up the wallpaper.
    /// Derived from the same hue wheel the wallpaper shifts through, so
    /// changing the wallpaper hue visibly changes the lip.
    static func lensTint(wallpaperShift: Double) -> Color {
        // Base is the wallpaper's mauve-champagne midpoint.
        let hue = (0.09 + wallpaperShift * 0.55).truncatingRemainder(dividingBy: 1)
        return Color(hue: hue, saturation: 0.38, brightness: 0.98)
    }

    // MARK: Wallpaper palette (champagne / ivory / mauve)

    static let champagne = Color(red: 0.953, green: 0.886, blue: 0.784)
    static let ivory = Color(red: 0.984, green: 0.965, blue: 0.925)
    static let bone = Color(red: 0.937, green: 0.902, blue: 0.824)
    static let gold = Color(red: 0.851, green: 0.714, blue: 0.514)
    static let taupe = Color(red: 0.718, green: 0.643, blue: 0.557)
    static let mauve = Color(red: 0.612, green: 0.545, blue: 0.631)
    static let blush = Color(red: 0.910, green: 0.780, blue: 0.753)
    static let deepMauve = Color(red: 0.431, green: 0.373, blue: 0.471)
    static let silverBlue = Color(red: 0.729, green: 0.749, blue: 0.804)
}
