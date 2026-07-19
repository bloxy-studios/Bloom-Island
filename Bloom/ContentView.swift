//
//  ContentView.swift
//  Bloom
//
//  Demo scene: a flowing champagne/ivory/mauve silk wallpaper (so the glass
//  always has something real to refract), the Dynamic Island pinned to the
//  top, and a small glass control strip to trigger each state and sample
//  activity. Tapping anywhere outside the island collapses it.
//

import CoreGraphics
import Foundation
import SwiftUI

struct ContentView: View {
    @State private var model = IslandViewModel()
    @State private var systemActivity = SystemLiveActivityController()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                WallpaperView(hueShift: model.wallpaperShift)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(GlassTokens.stateChange(reduceMotion: reduceMotion)) {
                            model.tapOutside()
                        }
                    }

                ControlStrip(model: model, systemActivity: systemActivity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 18)

                DynamicIslandView(model: model, containerWidth: proxy.size.width)
                    .padding(.top, IslandState.Metrics.topInset)
            }
            .ignoresSafeArea()
        }
        // The island lives in the top strip the system reserves for the
        // notification-center edge pan — defer that gesture so taps on the
        // pill reach the app, like the hardware island.
        .defersSystemGestures(on: .top)
    }
}

// MARK: - Wallpaper

/// Full-screen sculptural silk: a drifting mesh gradient color field with
/// bright specular ridge lines along each fold, per the design reference.
/// The hue shift control proves the island's glass responds to what's
/// behind it.
struct WallpaperView: View {
    var hueShift: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: DemoFlags.isUITesting)) { context in
            SilkCanvas(phase: context.date.timeIntervalSinceReferenceDate)
        }
        .hueRotation(.degrees(hueShift * 160))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Wallpaper")
        .accessibilityIdentifier("IslandCanvas")
    }
}

/// One frame of the silk wallpaper at a given animation phase.
private struct SilkCanvas: View {
    let phase: TimeInterval

    var body: some View {
        ZStack {
            baseMesh
            ribbonLayer
            depthShading
        }
    }

    // MARK: Base color field

    private var baseMesh: some View {
        MeshGradient(
            width: 4,
            height: 4,
            points: meshPoints,
            colors: Self.meshColors
        )
    }

    private var meshPoints: [SIMD2<Float>] {
        func drift(_ x: Double, _ y: Double, _ ax: Double, _ ay: Double, _ seed: Double) -> SIMD2<Float> {
            SIMD2<Float>(
                Float(x + ax * sin(phase * 0.18 + seed)),
                Float(y + ay * cos(phase * 0.15 + seed * 1.4))
            )
        }
        return [
            SIMD2<Float>(0, 0), SIMD2<Float>(0.34, 0), SIMD2<Float>(0.68, 0), SIMD2<Float>(1, 0),
            drift(0, 0.36, 0, 0.02, 0.5), drift(0.30, 0.30, 0.045, 0.04, 1.7),
            drift(0.66, 0.38, 0.05, 0.045, 2.9), drift(1, 0.32, 0, 0.03, 4.1),
            drift(0, 0.64, 0, 0.03, 5.3), drift(0.36, 0.68, 0.05, 0.05, 6.5),
            drift(0.70, 0.62, 0.045, 0.04, 7.7), drift(1, 0.68, 0, 0.02, 8.9),
            SIMD2<Float>(0, 1), SIMD2<Float>(0.32, 1), SIMD2<Float>(0.66, 1), SIMD2<Float>(1, 1),
        ]
    }

    /// Row-major, top to bottom: gold glow upper-left, ivory folds through
    /// the middle, mauve pooling lower-left, silver-blue lower-right.
    private static let meshColors: [Color] = [
        GlassTokens.gold, GlassTokens.ivory, GlassTokens.bone, GlassTokens.champagne,
        GlassTokens.champagne, GlassTokens.ivory, GlassTokens.taupe, GlassTokens.bone,
        GlassTokens.taupe, GlassTokens.mauve, GlassTokens.bone, GlassTokens.silverBlue,
        GlassTokens.deepMauve, GlassTokens.mauve, GlassTokens.silverBlue, GlassTokens.silverBlue,
    ]

    // MARK: Ribbon ridge highlights

    private static let ribbons: [Ribbon] = [
        Ribbon(start: CGPoint(x: 0.55, y: -0.03), c1: CGPoint(x: 0.10, y: 0.24),
               c2: CGPoint(x: 0.90, y: 0.42), end: CGPoint(x: 0.12, y: 1.02),
               brightness: 0.9, seed: 0),
        Ribbon(start: CGPoint(x: 0.72, y: -0.06), c1: CGPoint(x: 0.28, y: 0.28),
               c2: CGPoint(x: 0.86, y: 0.55), end: CGPoint(x: 0.42, y: 1.04),
               brightness: 0.6, seed: 2.1),
        Ribbon(start: CGPoint(x: -0.04, y: 0.42), c1: CGPoint(x: 0.55, y: 0.40),
               c2: CGPoint(x: 0.05, y: 0.72), end: CGPoint(x: 0.90, y: 1.03),
               brightness: 0.75, seed: 4.2),
        Ribbon(start: CGPoint(x: 1.04, y: 0.34), c1: CGPoint(x: 0.55, y: 0.50),
               c2: CGPoint(x: 0.16, y: 0.72), end: CGPoint(x: 0.62, y: 1.05),
               brightness: 0.5, seed: 6.3),
        Ribbon(start: CGPoint(x: 0.90, y: 0.06), c1: CGPoint(x: 0.60, y: 0.16),
               c2: CGPoint(x: 0.35, y: 0.22), end: CGPoint(x: -0.02, y: 0.30),
               brightness: 0.35, seed: 8.4),
    ]

    private var ribbonLayer: some View {
        ZStack {
            ForEach(Self.ribbons.indices, id: \.self) { index in
                let ribbon = Self.ribbons[index]
                let wobble = CGFloat(sin(phase * 0.22 + ribbon.seed) * 0.018)
                let curve = RibbonCurve(ribbon: ribbon, wobble: wobble)

                // Soft shadow beneath the fold.
                curve
                    .stroke(
                        GlassTokens.deepMauve.opacity(0.20 * ribbon.brightness),
                        style: StrokeStyle(lineWidth: 30, lineCap: .round)
                    )
                    .blur(radius: 22)
                    .offset(y: 14)
                    .blendMode(.multiply)

                // Wide glow of the lit fold.
                curve
                    .stroke(
                        Color.white.opacity(0.12 * ribbon.brightness),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .blur(radius: 16)
                    .blendMode(.screen)

                // Focused sheen.
                curve
                    .stroke(
                        Color.white.opacity(0.32 * ribbon.brightness),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .blur(radius: 3)
                    .blendMode(.screen)

                // Crisp specular ridge line.
                curve
                    .stroke(
                        Color.white.opacity(0.8 * ribbon.brightness),
                        style: StrokeStyle(lineWidth: 1.3, lineCap: .round)
                    )
                    .blur(radius: 0.3)
                    .blendMode(.screen)
            }
        }
    }

    // MARK: Depth

    private var depthShading: some View {
        ZStack {
            RadialGradient(
                colors: [GlassTokens.gold.opacity(0.45), .clear],
                center: UnitPoint(x: 0.08, y: 0.12),
                startRadius: 0,
                endRadius: 430
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [.clear, GlassTokens.deepMauve.opacity(0.4)],
                startPoint: UnitPoint(x: 0.75, y: 0.15),
                endPoint: UnitPoint(x: 0, y: 1)
            )
            .blendMode(.multiply)
        }
    }
}

/// A silk fold in unit coordinates.
private struct Ribbon {
    let start: CGPoint
    let c1: CGPoint
    let c2: CGPoint
    let end: CGPoint
    let brightness: Double
    let seed: Double
}

/// The fold's ridge as a cubic Bézier, gently wobbled by the animation phase.
private struct RibbonCurve: Shape {
    var ribbon: Ribbon
    var wobble: CGFloat

    func path(in rect: CGRect) -> Path {
        func point(_ unit: CGPoint, dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint {
            CGPoint(
                x: rect.minX + (unit.x + dx) * rect.width,
                y: rect.minY + (unit.y + dy) * rect.height
            )
        }
        var path = Path()
        path.move(to: point(ribbon.start))
        path.addCurve(
            to: point(ribbon.end),
            control1: point(ribbon.c1, dx: wobble, dy: wobble * 0.4),
            control2: point(ribbon.c2, dx: -wobble, dy: -wobble * 0.5)
        )
        return path
    }
}

// MARK: - Control strip

/// Small glass chips that drive every island state, plus a hue slider that
/// recolors the wallpaper to prove the glass lip responds to it.
private struct ControlStrip: View {
    var model: IslandViewModel
    var systemActivity: SystemLiveActivityController

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 14) {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    chip("Pill", symbol: "capsule.fill", identifier: "ControlCompact") {
                        model.collapse()
                    }
                    chip("Music", symbol: "music.note", identifier: "ControlMusic") {
                        model.show(.music)
                    }
                    chip("Timer", symbol: "timer", identifier: "ControlTimer") {
                        model.show(.timer)
                    }
                    chip("Actions", symbol: "square.grid.2x2.fill", identifier: "ControlActions") {
                        model.showActions()
                    }
                }
            }

            systemActivityRow()

            sliderRow()
        }
        .padding(.horizontal, 20)
    }

    /// Starts/ends the real ActivityKit Live Activity for the current
    /// selection, surfacing authorization or request problems inline.
    @ViewBuilder
    private func systemActivityRow() -> some View {
        let button = Button {
            systemActivity.toggle(for: model)
        } label: {
            Label(
                systemActivity.isRunning ? "End Live Activity" : "System Live Activity",
                systemImage: systemActivity.isRunning
                    ? "stop.circle.fill"
                    : "dot.radiowaves.left.and.right"
            )
            .font(.system(size: 12, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 2)
            .padding(.vertical, 6)
        }
        .accessibilityIdentifier("ControlSystemActivity")

        HStack(spacing: 10) {
            if reduceTransparency {
                button.buttonStyle(.bordered)
            } else {
                button.buttonStyle(.glass)
            }

            if let message = systemActivity.statusMessage {
                Text(message)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(GlassTokens.deepMauve)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func chip(
        _ title: String,
        symbol: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button {
            withAnimation(GlassTokens.stateChange(reduceMotion: reduceMotion)) {
                action()
            }
        } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 2)
                .padding(.vertical, 6)
        }
        .accessibilityIdentifier(identifier)

        if reduceTransparency {
            button.buttonStyle(.bordered)
        } else {
            button.buttonStyle(.glass)
        }
    }

    @ViewBuilder
    private func sliderRow() -> some View {
        @Bindable var bindableModel = model
        let row = HStack(spacing: 12) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GlassTokens.deepMauve)

            Slider(value: $bindableModel.wallpaperShift, in: 0...1)
                .tint(GlassTokens.lensTint(wallpaperShift: model.wallpaperShift))
                .accessibilityIdentifier("WallpaperHueSlider")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)

        if reduceTransparency {
            row.background(Capsule().fill(Color.white.opacity(0.92)))
        } else {
            row.glassEffect(.regular, in: .capsule)
        }
    }
}

#Preview {
    ContentView()
}
