//
//  ToolcastInfo.swift
//  HiPixel
//
//  Created by 十里 on 2025/7/28.
//

import Foundation

struct ToolcastInfo: Codable {
    let version: String
    let bin: ResourceInfo
    let models: ResourceInfo
}

struct ResourceInfo: Codable {
    let url: String
    let sha256: String
}

// MARK: - ToolcastInfo Extensions
extension ToolcastInfo {
    static func fetch() async throws -> ToolcastInfo {
        let url = URL(string: "https://releases.5km.tech/hipixel/toolscast.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ToolcastInfo.self, from: data)
    }
}
