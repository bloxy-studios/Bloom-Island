# Bloom Island — Dynamic Island recreation with Liquid Glass

> Build brief for coding agents and contributors. Read fully before writing code.

## Context

- Repo: `bloxy-studios/Bloom-Island` — a SwiftUI + SwiftData iOS app. Xcode project
  `Bloom.xcodeproj`, scheme `Bloom`; targets: `Bloom`, `BloomTests`, `BloomUITests`.
- The app is still the stock Xcode template. Replace the template UI entirely
  (`ContentView.swift` list, `Item.swift` SwiftData model — delete unless genuinely reused).
- Deployment target: the app target is **iOS 26.0** (the Liquid Glass baseline — do not raise it).
  Project-level and test-target values may still read 26.5; aligning them down to 26.0 is welcome.
- CI: `.github/workflows/ios.yml` runs on `macos-26` (Xcode 26.5 default), pins scheme `Bloom`,
  picks the newest-runtime iPhone simulator by UDID via `simctl`, pre-boots it, then runs
  `xcodebuild build-for-testing` + `test-without-building` serially with per-test timeouts
  (results bundle uploaded as an artifact on failure). Every commit must keep this green.
  Do not edit workflow files as part of feature work.

## Goal

Recreate the iPhone Dynamic Island *inside the app*: a floating, morphing island pinned to
the top of the screen that expands into Live Activity layouts and a glass action bar, styled
with iOS 26 Liquid Glass. The bar for motion and materials is "indistinguishable from
Apple's own island" — fluid, springy, weighty, never linear.

## Design language (the heart of this task)

- Collapsed, the island reads as hardware: a true-black capsule sitting exactly over the
  sensor housing — ≈126 × 37.3 pt, top inset ≈11 pt (iPhone Pro class), perfect capsule corners.
- Liquid Glass: expanded surfaces are not flat black. The lower edge carries a refractive
  glass lip that bends the wallpaper behind it — a bright specular band, faint chromatic
  fringing at the rim, wallpaper color bleeding upward into the black like light through
  the bottom of a lens.
- Use the real APIs, not fakes: `glassEffect(_:in:)`, `GlassEffectContainer`,
  `glassEffectID(_:in:)` with `@Namespace` so separate glass elements merge and split
  fluidly; `.buttonStyle(.glass)` / `.glassProminent` for actions; `.interactive()` glass
  on anything tappable.
- Demo canvas: a full-screen flowing champagne/ivory/mauve wallpaper (layered `MeshGradient`
  ribbons with soft specular ridge highlights — sculptural silk, not a flat gradient) so the
  glass always has something real to refract.

## States — single source of truth: an `IslandState` enum

1. `compact` — the hardware pill. Optional tiny leading/trailing glyphs (waveform, timer)
   flanking a black center that stays black (the "sensor" region is never covered).
2. `live(activity)` — expanded Live Activity card: grows downward/outward to
   ≈ screen width − 28 pt, corner radius ≈44 pt continuous, height ≤160 pt. Layout mirrors
   ActivityKit's regions — leading (artwork/icon), center (title + subtitle), trailing
   (metric/countdown), bottom (progress or action row) — so this design can later be lifted
   into a real ActivityKit widget unchanged. Ship two sample activities: music player and timer.
3. `actions` — the island blooms into a glass action bar: a row of capsule glass buttons
   (icon + label), one tinted `.glassProminent` primary. All buttons live in one
   `GlassEffectContainer` so neighboring glass melts together mid-morph.

## Motion

- Springs only: `.spring(response: 0.45, dampingFraction: 0.72)` for geometry, `.snappy`
  for content. Never ease-in-out, never linear.
- Content swaps via blur + scale + opacity (`.transition(.blurReplace)`); live numbers use
  `.contentTransition(.numericText())`.
- The island stretches slightly toward touch (scale anchored at top), overshoots on expand,
  settles with one soft bounce. Tap outside collapses it.
- Haptics via `.sensoryFeedback`: light impact on expand, soft on collapse.
- Respect `accessibilityReduceMotion` (crossfade instead of springs) and
  `accessibilityReduceTransparency` (solid fills instead of glass).

## Architecture

- `Island/IslandState.swift` — state enum + per-state geometry (size, corner radius, insets)
  as pure values → unit-testable without UI.
- `Island/IslandViewModel.swift` — `@Observable`; drives transitions and demo activity data.
- `Island/DynamicIslandView.swift` — the reusable component, mounted with
  `.overlay(alignment: .top)` over content that ignores the top safe area.
- `Island/GlassTokens.swift` — glass styles, tints, shadows, corner metrics in one place.
- `ContentView.swift` — demo screen: wallpaper + island + a small control strip to trigger
  each state and sample activity.
- SwiftUI previews for every state.

## Tests (CI must stay green)

- `BloomTests`: state-machine transitions + per-state geometry values.
- `BloomUITests`: tap island → expanded layout appears; tap outside → collapses.

## Acceptance

- Motion feels Apple-native: no jump cuts, no clipped shadows, smooth at 120 Hz.
- The glass genuinely responds to what's behind it (shift the wallpaper hue → the lip changes).
- Every state reachable from the demo controls; no template cruft remains.
- `xcodebuild test` passes on an iPhone simulator via `ios.yml`.

## Out of scope (for now)

- A real ActivityKit/WidgetKit extension target. The design must be lift-ready (region
  naming above), but don't add the target yet — CI is pinned to the `Bloom` scheme and
  workflow changes are handled separately.
