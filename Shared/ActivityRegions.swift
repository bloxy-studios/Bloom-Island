//
//  ActivityRegions.swift
//  Bloom
//
//  The live-activity region views (ActivityKit's leading / center /
//  trailing / bottom), shared between the in-app island and the future
//  BloomIslandWidgets extension (PR C of the ActivityKit lift plan).
//
//  One layout, two hosts: the `.island` context renders from a host-driven
//  clock date with ambient animation; the `.widget` context renders static
//  snapshots and delegates time to the system's interval-driven APIs
//  (`Text(timerInterval:)` / `ProgressView(timerInterval:)`).
//
//  This file must reference only Foundation, SwiftUI and the shared
//  BloomActivityAttributes — no demo model, no glass tokens.
//

import Foundation
import SwiftUI

// MARK: - Rendering context

/// How the shared region views are being hosted.
enum ActivityRenderingContext {
    /// Inside the in-app island: the host supplies a ticking `now` date
    /// (via TimelineView) and ambient animation is allowed.
    case island
    /// Inside a WidgetKit extension: static snapshot rendering, with
    /// countdowns and progress driven by system interval APIs.
    case widget
}

// MARK: - Shared accents

extension BloomActivityAttributes.Kind {

    /// Canonical per-activity accent. The app's glass tokens delegate here
    /// so the widget target renders identical colors without importing
    /// app-side styling.
    var accent: Color {
        switch self {
        case .music: Color(red: 0.94, green: 0.72, blue: 0.44)
        case .timer: Color(red: 0.80, green: 0.62, blue: 0.86)
        }
    }
}

// MARK: - Shared palette

/// Colors the shared regions need beyond the kind accents. Values mirror
/// the app's glass tokens (asserted by unit test) without importing them.
enum ActivityPalette {

    /// Deep mauve base of the artwork tile gradient — same value as
    /// `GlassTokens.deepMauve`.
    static let artworkShadow = Color(red: 0.431, green: 0.373, blue: 0.471)
}

// MARK: - Shared formatting

enum ActivityFormat {

    /// Formats a number of seconds as `m:ss` (e.g. 754 → "12:34").
    /// Canonical here; `IslandViewModel.formattedCountdown` delegates.
    static func countdown(_ seconds: TimeInterval) -> String {
        let whole = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }
}

// MARK: - Expanded card

/// The expanded live-activity layout, mirroring ActivityKit's regions —
/// leading (artwork/icon), center (title + subtitle), trailing
/// (metric/countdown), bottom (progress or action row).
struct ActivityCardView: View {

    let attributes: BloomActivityAttributes
    let content: BloomActivityAttributes.ContentState
    var renderingContext: ActivityRenderingContext = .island
    /// The host clock for `.island` rendering; ignored in `.widget`.
    var now: Date = Date()
    /// Whether the waveform may animate (`.island` only).
    var waveformAnimated: Bool = true

    private var accent: Color { attributes.kind.accent }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                leadingRegion
                centerRegion
                Spacer(minLength: 8)
                trailingRegion
            }
            bottomRegion
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }

    // MARK: Leading region

    /// Exposed for `DynamicIslandExpandedRegion(.leading)` in the widget.
    var leadingRegion: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        accent.opacity(0.92),
                        ActivityPalette.artworkShadow.opacity(0.72),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 44, height: 44)
            .overlay {
                Image(systemName: attributes.leadingSymbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }

    // MARK: Center region

    /// Exposed for `DynamicIslandExpandedRegion(.center)` in the widget.
    var centerRegion: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(attributes.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text(attributes.subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
        }
        .lineLimit(1)
    }

    // MARK: Trailing region

    /// Exposed for `DynamicIslandExpandedRegion(.trailing)` in the widget.
    @ViewBuilder
    var trailingRegion: some View {
        switch attributes.kind {
        case .music:
            WaveformGlyph(
                tint: accent,
                animated: renderingContext == .island && waveformAnimated
            )

        case .timer:
            switch renderingContext {
            case .island:
                let remaining = ActivityFormat.countdown(content.timerRemaining(at: now) ?? 0)
                Text(remaining)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .foregroundStyle(accent)
                    .animation(.snappy, value: remaining)

            case .widget:
                if let range = content.timerRange {
                    Text(timerInterval: range, countsDown: true)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                }
            }
        }
    }

    // MARK: Bottom region

    /// Exposed for `DynamicIslandExpandedRegion(.bottom)` in the widget.
    @ViewBuilder
    var bottomRegion: some View {
        switch attributes.kind {
        case .music:
            if case .music(let songStart, let duration) = content.payload {
                VStack(spacing: 8) {
                    switch renderingContext {
                    case .island:
                        MeasuredProgressBar(
                            fraction: content.musicProgress(at: now) ?? 0,
                            tint: accent
                        )

                        let elapsed = content.musicElapsed(at: now) ?? 0
                        HStack {
                            Text(ActivityFormat.countdown(elapsed))
                            Spacer()
                            Text("-" + ActivityFormat.countdown(max(0, duration - elapsed)))
                        }
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.55))

                    case .widget:
                        let songRange = songStart...songStart.addingTimeInterval(max(0, duration))
                        systemProgressBar(over: songRange, countsDown: false)

                        HStack {
                            Text(timerInterval: songRange, countsDown: false)
                            Spacer()
                            Text("-") + Text(timerInterval: songRange, countsDown: true)
                        }
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.55))
                    }

                    HStack(spacing: 34) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "pause.fill")
                            .font(.system(size: 22, weight: .semibold))
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 2)
                }
            }

        case .timer:
            VStack(spacing: 8) {
                switch renderingContext {
                case .island:
                    MeasuredProgressBar(
                        fraction: content.timerFraction(at: now) ?? 0,
                        tint: accent
                    )
                case .widget:
                    if let range = content.timerRange {
                        systemProgressBar(over: range, countsDown: true)
                    }
                }

                HStack {
                    Text(attributes.subtitle.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                    Spacer()
                    Image(systemName: attributes.trailingSymbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    /// System-driven progress for widget snapshots — the system animates
    /// the fill without the extension re-rendering.
    private func systemProgressBar(over range: ClosedRange<Date>, countsDown: Bool) -> some View {
        ProgressView(timerInterval: range, countsDown: countsDown) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(accent)
    }
}

// MARK: - Measured progress bar (island context)

/// The in-app island's custom capsule progress bar.
struct MeasuredProgressBar: View {
    let fraction: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                Capsule()
                    .fill(tint)
                    .frame(width: max(5, proxy.size.width * CGFloat(fraction)))
            }
        }
        .frame(height: 5)
    }
}

// MARK: - Waveform glyph

/// A tiny equalizer. Animated in the island; a static, deterministic bar
/// cluster in widget snapshots and under UI tests.
struct WaveformGlyph: View {
    let tint: Color
    var animated: Bool = true

    var body: some View {
        Group {
            if animated {
                TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
                    bars(phase: context.date.timeIntervalSinceReferenceDate)
                }
            } else {
                bars(phase: 0)
            }
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }

    private func bars(phase: TimeInterval) -> some View {
        HStack(spacing: 2.5) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(tint)
                    .frame(width: 3, height: barHeight(index: index, phase: phase))
            }
        }
    }

    private func barHeight(index: Int, phase: TimeInterval) -> CGFloat {
        let wave = sin(phase * 5.2 + Double(index) * 1.7)
        return 6 + CGFloat((wave + 1) / 2) * 10
    }
}

// MARK: - Widget-context previews

/// Previews of the widget rendering path on an island-black card, so the
/// PR C layouts can be eyeballed before the extension target exists.
private struct WidgetContextPreview: View {
    let attributes: BloomActivityAttributes
    let content: BloomActivityAttributes.ContentState
    let height: CGFloat

    var body: some View {
        ZStack {
            Color(red: 0.09, green: 0.085, blue: 0.10)
                .ignoresSafeArea()

            ActivityCardView(
                attributes: attributes,
                content: content,
                renderingContext: .widget
            )
            .frame(width: 374, height: height)
            .background(
                RoundedRectangle(cornerRadius: 44, style: .continuous)
                    .fill(Color.black)
            )
        }
    }
}

#Preview("Widget context — Music") {
    WidgetContextPreview(
        attributes: BloomActivityAttributes(
            kind: .music,
            title: "Golden Hour",
            subtitle: "Sable Rivers",
            leadingSymbol: "music.note",
            trailingSymbol: "waveform"
        ),
        content: .music(start: Date(), duration: 222),
        height: 160
    )
}

#Preview("Widget context — Timer") {
    WidgetContextPreview(
        attributes: BloomActivityAttributes(
            kind: .timer,
            title: "Focus Timer",
            subtitle: "Deep work",
            leadingSymbol: "timer",
            trailingSymbol: "pause.fill"
        ),
        content: .timer(start: Date(), duration: 15 * 60),
        height: 136
    )
}
