//
//  AppInstallationChecker.swift
//  HiPixel
//
//  Created by 十里 on 2025/11/10.
//

import Foundation
import AppKit

enum AppInstallationChecker {
    static func isAppInstalled(bundleIdentifier: String) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }
    
    static func openAppStore(url: String) {
        guard let url = URL(string: url) else { return }
        NSWorkspace.shared.open(url)
    }
}
