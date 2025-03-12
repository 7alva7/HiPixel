//
//  AppInfo.swift
//  HiPixel
//
//  Created by 十里 on 2025/03/11.
//

import Foundation

enum AppInfo {
    static let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "HiPixel"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
