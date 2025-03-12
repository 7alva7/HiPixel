//
//  MonitorItem.swift
//  HiPixel
//
//  Created by 十里 on 2025/03/11.
//

import Foundation

struct MonitorItem: Codable, Identifiable {
    var id: String = UUID().uuidString
    var url: URL
    var enabled: Bool = true
}
