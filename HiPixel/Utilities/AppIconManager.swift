//
//  AppIconManager.swift
//  HiPixel
//
//  Created by 十里 on 2025/11/10.
//

import SwiftUI

@MainActor
class AppIconManager {
    static let shared = AppIconManager()
    
    @AppStorage(HiPixelConfiguration.Keys.SelectedAppIcon) var selectedAppIcon: HiPixelConfiguration.AppIcon?
    
    func applyAppIcon() {
        guard let selectedAppIcon else { return }
        setAppIcon(selectedAppIcon)
    }
    
    func getCurrentAppIcon() -> HiPixelConfiguration.AppIcon {
        if let bundleIcon = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconFile") as? String {
            return HiPixelConfiguration.AppIcon(rawValue: bundleIcon) ?? .primary
        }
        return .primary
    }
    
    func setAppIcon(_ icon: HiPixelConfiguration.AppIcon) {
        UserDefaults.standard.set(icon.rawValue, forKey: "SelectedAppIcon")
        if icon == .primary {
            NSApplication.shared.applicationIconImage = nil
        } else {
            NSApplication.shared.applicationIconImage = icon.previewImage
        }
    }
}
