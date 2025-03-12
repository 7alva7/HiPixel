//
//  Logger.swift
//  HiPixel
//
//  Created by 十里 on 2025/03/11.
//

import Foundation
import os

extension Common {
    static let logger = Logger(
        subsystem: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "tech.5km.HiPixel",
        category: "main"
    )
}
