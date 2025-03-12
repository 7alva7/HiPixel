//
//  Directories.swift
//  HiPixel
//
//  Created by 十里 on 2025/03/11.
//

import Foundation

extension Common {
    static let directory: URL = {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        let dir = appSupportURL.appendingPathComponent("hipixel")
        DispatchQueue.main.async {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                Common.logger.error("Create \(dir) failed: \(error)")
            }
        }
        return dir
    }()
}
