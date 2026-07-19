//
//  SystemLiveActivityController.swift
//  Bloom
//
//  Requests and ends the real ActivityKit Live Activity for the demo,
//  using the exact lifted attributes + content state the in-app island
//  renders — the widget shows what the island shows.
//

import ActivityKit
import Foundation
import Observation

@Observable
final class SystemLiveActivityController {

    /// Whether a system Live Activity started by this controller is running.
    private(set) var isRunning = false

    /// Human-readable status for the demo strip (authorization problems,
    /// request errors, or a running confirmation).
    private(set) var statusMessage: String?

    private var activity: Activity<BloomActivityAttributes>?

    /// Starts or ends the system activity for the model's selection.
    func toggle(for model: IslandViewModel) {
        if isRunning {
            end()
        } else {
            start(for: model)
        }
    }

    /// Requests a system Live Activity mirroring the island's current
    /// selection and demo clocks.
    func start(for model: IslandViewModel) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusMessage = "Live Activities are disabled for Bloom"
            return
        }

        let lifted = model.liftedActivity(for: model.selectedActivity)
        do {
            activity = try Activity.request(
                attributes: lifted.attributes,
                content: ActivityContent(state: lifted.state, staleDate: nil)
            )
            isRunning = true
            statusMessage = "Live Activity running — lock the screen or check the island"
        } catch {
            isRunning = false
            statusMessage = "Couldn't start: \(error.localizedDescription)"
        }
    }

    /// Ends the activity this controller started, dismissing it immediately.
    func end() {
        isRunning = false
        statusMessage = nil
        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
