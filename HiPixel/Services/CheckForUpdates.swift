//
//  CheckForUpdates.swift
//  HiPixel
//
//  Created by 十里 on 2025/2/4.
//

import Sparkle
import SwiftUI

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button(action: updater.checkForUpdates) {
            Label("Check for Updates…", systemImage: "arrow.trianglehead.2.counterclockwise")
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}
