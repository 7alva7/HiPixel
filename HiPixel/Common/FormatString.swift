//
//  FormatString.swift
//  HiPixel
//
//  Created by 十里 on 2025/03/11.
//

import Foundation

extension Common {
    static func timeString(from seconds: Int, simplified: Bool = false) -> String {
        let minutes = seconds % 3600 / 60
        let hours = seconds / 3600
        let remainingSeconds = seconds % 60
        if hours == 0 && simplified {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}
