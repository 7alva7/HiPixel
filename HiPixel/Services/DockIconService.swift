//
//  DockIconService.swift
//  HiPixel
//
//  Created by 十里 on 2025/11/10.
//

import AppKit

@MainActor
class DockIconService {
    static let shared = DockIconService()
    
    private init() {}
    
    /// Hide or show the dock icon based on the provided value
    /// - Parameter hidden: true to hide dock icon, false to show it
    /// - Returns: true if user should be warned about menu bar access, false otherwise
    func setDockIconHidden(_ hidden: Bool) -> Bool {
        if hidden {
            NSApp.setActivationPolicy(.accessory)
            // Check if menu bar extra is enabled, if not, return true to warn user
            return !HiPixelConfiguration.shared.showMenuBarExtra
        } else {
            NSApp.setActivationPolicy(.regular)
            return false
        }
    }
    
    /// Get current dock icon visibility state
    /// - Returns: true if dock icon is hidden, false if visible
    var isDockIconHidden: Bool {
        return NSApp.activationPolicy() == .accessory
    }
}

