//
//  DynamicIslandView.swift
//  Bloom
//
//  The reusable in-app Dynamic Island. Mount with .overlay(alignment: .top)
//  (or as the top-aligned child of a ZStack) over content that ignores the
//  top safe area.
//
//  All glass lives in one GlassEffectContainer so the pill, the live
//  activity card and the action buttons melt into each other mid-morph.
//

import CoreGraphics
import Foundation
import SwiftUI

/// Runtime flags for the demo scene. UI tests pass `--island-uitests` to
/// freeze ambient animation so XCUITest's quiescence detection stays fast.
enum DemoFlags {
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("--island-uitests")
}

// MARK: - Dynamic Island

struct DynamicIslandView: View {

    var model: IslandViewModel
    var containerWidth: CGFloat

    @Namespace private var glassNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isPressed = false

    private var geometry: IslandGeometry {
        model.state.geometry(in: containerWidth)
    }

    var body: some View {
        GlassEffectContainer(spacing: GlassTokens.morphSpacing) {
            switch model.state {
            case .actions:
                actionBar
                    .transition(GlassTokens.contentTransition(reduceMotion: reduceMotion))
            default:
                islandSurface
                    .transition(GlassTokens.contentTransition(reduceMotion: reduceMotion))
            }
        }
        .sensoryFeedback(trigger: model.state) { oldValue, newValue in
            if !oldValue.isExpanded && newValue.isExpanded {
                return .impact(weight: .light)
            }
            if oldValue.isExpanded && !newValue.isExpanded {
                return .impact(flexibility: .soft)
            }
            return nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("DynamicIsland")
    }

    // MARK: Surface (compact + live share one identity so the frame morphs)

    private var islandSurface: some View {
        let geo = geometry
        return surfaceChrome(cornerRadius: geo.cornerRadius) {
            ZStack {
                switch model.state {
                case .live(let activity):
                    LiveActivityCard(activity: activity, model: model)
                        .transition(GlassTokens.contentTransition(reduceMotion: reduceMotion))
                default:
                    CompactContent(activity: model.selectedActivity, model: model)
                        .transition(GlassTokens.contentTransition(reduceMotion: reduceMotion))
                }
            }
            .frame(width: geo.width, height: geo.height)
        }
        .overlay {
            LensLip(
                cornerRadius: geo.cornerRadius,
                tint: GlassTokens.lensTint(wallpaperShift: model.wallpaperShift)
            )
            .opacity(model.state.isExpanded ? 1 : 0.55)
            .allowsHitTesting(false)
        }
        .scaleEffect(
            x: isPressed ? 1.03 : 1,
            y: isPressed ? 1.05 : 1,
            anchor: .top
        )
        // Like the hardware island, the collapsed pill's touch target
        // extends below it — the pill itself sits in the system's
        // status-bar strip, where touches are unreliable.
        .padding(.bottom, model.state.isExpanded ? 0 : GlassTokens.compactTouchGrace)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(GlassTokens.stateChange(reduceMotion: reduceMotion)) {
                model.tapIsland()
            }
        }
        .onLongPressGesture(
            minimumDuration: 0.35,
            maximumDistance: 24,
            perform: {},
            onPressingChanged: { pressing in
                withAnimation(GlassTokens.pressSpring) { isPressed = pressing }
            }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(model.state.isExpanded ? "Dynamic Island, expanded" : "Dynamic Island")
    }

    /// Near-black interactive glass, or a solid fill under Reduce Transparency.
    @ViewBuilder
    private func surfaceChrome<Content: View>(
        cornerRadius: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if reduceTransparency {
            content()
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(GlassTokens.opaqueSurface)
                )
        } else {
            content()
                .glassEffect(
                    GlassTokens.surfaceGlass(expanded: model.state.isExpanded),
                    in: .rect(cornerRadius: cornerRadius)
                )
                .glassEffectID("island", in: glassNamespace)
                .glassEffectTransition(.matchedGeometry)
        }
    }

    // MARK: Action bar

    private var actionBar: some View {
        let geo = geometry
        return HStack(spacing: GlassTokens.actionSpacing) {
            secondaryActionButton("Love", symbol: "heart.fill", glassID: "action-love") {
                model.collapse()
            }

            primaryActionButton("Reply", symbol: "arrowshape.turn.up.left.fill") {
                model.collapse()
            }

            secondaryActionButton("More", symbol: "ellipsis", glassID: "action-more") {
                model.show(model.selectedActivity)
            }
        }
        .frame(width: geo.width, height: geo.height)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("IslandActionBar")
    }

    @ViewBuilder
    private func secondaryActionButton(
        _ title: String,
        symbol: String,
        glassID: String,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button {
            withAnimation(GlassTokens.stateChange(reduceMotion: reduceMotion)) {
                action()
            }
        } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }

        if reduceTransparency {
            button.buttonStyle(.bordered)
        } else {
            button
                .buttonStyle(.glass)
                .glassEffectID(glassID, in: glassNamespace)
                .glassEffectTransition(.matchedGeometry)
        }
    }

    @ViewBuilder
    private func primaryActionButton(
        _ title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button {
            withAnimation(GlassTokens.stateChange(reduceMotion: reduceMotion)) {
                action()
            }
        } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .tint(GlassTokens.primaryActionTint)

        if reduceTransparency {
            button.buttonStyle(.borderedProminent)
        } else {
            button
                .buttonStyle(.glassProminent)
                .glassEffectID("action-reply", in: glassNamespace)
                .glassEffectTransition(.matchedGeometry)
        }
    }
}

// MARK: - Compact content

/// The hardware pill: tiny glyphs flank a center that stays black — the
/// "sensor" region is never covered.
private struct CompactContent: View {
    let activity: LiveActivity
    let model: IslandViewModel

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: activity.leadingSymbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GlassTokens.accent(for: activity))

            Spacer(minLength: 44)

            trailing
        }
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("IslandCompactContent")
    }

    @ViewBuilder
    private var trailing: some View {
        switch activity.kind {
        case .music:
            WaveformGlyph(
                tint: GlassTokens.accent(for: activity),
                animated: !DemoFlags.isUITesting
            )
        case .timer:
            TimelineView(.periodic(from: .now, by: DemoFlags.isUITesting ? 3600 : 1)) { context in
                Text(IslandViewModel.formattedCountdown(model.timerRemaining(at: context.date)))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .foregroundStyle(GlassTokens.accent(for: activity))
            }
        }
    }
}

// MARK: - Live activity card

/// Thin island-side host for the shared `ActivityCardView`: it supplies the
/// ticking clock, then renders the exact attributes + content state the
/// future widget target will receive — so the in-app island and the system
/// island can never drift apart.
private struct LiveActivityCard: View {
    let activity: LiveActivity
    let model: IslandViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: DemoFlags.isUITesting ? 3600 : 1)) { context in
            ActivityCardView(
                attributes: BloomActivityAttributes(lifting: activity),
                content: model.liftedContentState(for: activity),
                renderingContext: .island,
                now: context.date,
                waveformAnimated: !DemoFlags.isUITesting
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("IslandLiveCard")
    }
}

// MARK: - Lens lip

/// The refractive lower edge, per the design reference: the top of the
/// island stays hardware black while wallpaper light pools upward through
/// a soft elliptical waterline, crossed by a broad specular band, with a
/// faint chromatic fringe at the rim — light through the bottom of a lens.
private struct LensLip: View {
    let cornerRadius: CGFloat
    let tint: Color

    var body: some View {
        ZStack {
            // Wallpaper light pooling up from below the bottom edge; the
            // top arc of the ellipse forms the lens waterline.
            Rectangle()
                .fill(
                    EllipticalGradient(
                        gradient: Gradient(stops: [
                            .init(color: tint.opacity(0.5), location: 0),
                            .init(color: tint.opacity(0.2), location: 0.55),
                            .init(color: .clear, location: 1),
                        ]),
                        center: UnitPoint(x: 0.5, y: 1.28),
                        startRadiusFraction: 0,
                        endRadiusFraction: 1.05
                    )
                )
                .blendMode(.plusLighter)

            // Broad specular band across the lower glass.
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.66),
                    .init(color: .white.opacity(0.34), location: 0.8),
                    .init(color: .white.opacity(0.08), location: 0.92),
                    .init(color: .white.opacity(0.4), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blur(radius: 3)
            .blendMode(.screen)

            // Crisp specular line hugging the lower rim.
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.05), location: 0),
                            .init(color: .white.opacity(0.02), location: 0.55),
                            .init(color: .white.opacity(0.55), location: 0.92),
                            .init(color: .white.opacity(0.85), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )
                .blur(radius: 0.4)
                .blendMode(.screen)

            // Faint chromatic fringing: offset cyan and magenta hairlines.
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [.clear, .clear, Color.cyan.opacity(0.28)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.7
                )
                .offset(y: -0.6)
                .blendMode(.plusLighter)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [.clear, .clear, Color(red: 1, green: 0.3, blue: 0.65).opacity(0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.7
                )
                .offset(y: 0.6)
                .blendMode(.plusLighter)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Previews

private struct IslandStatePreview: View {
    @State private var model: IslandViewModel

    init(state: IslandState) {
        _model = State(initialValue: IslandViewModel(state: state))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                WallpaperView(hueShift: 0)

                DynamicIslandView(model: model, containerWidth: proxy.size.width)
                    .padding(.top, IslandState.Metrics.topInset)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview("Compact") {
    IslandStatePreview(state: .compact)
}

#Preview("Live — Music") {
    IslandStatePreview(state: .live(.music))
}

#Preview("Live — Timer") {
    IslandStatePreview(state: .live(.timer))
}

#Preview("Actions") {
    IslandStatePreview(state: .actions)
}
