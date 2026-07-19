//
//  BloomIslandWidgetsBundle.swift
//  BloomIslandWidgets
//
//  Bloom ships one widget: the island's Live Activity.
//

import SwiftUI
import WidgetKit

@main
struct BloomIslandWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BloomIslandWidgetsLiveActivity()
    }
}
