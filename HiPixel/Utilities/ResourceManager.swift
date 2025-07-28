//
//  ResourceManager.swift
//  HiPixel
//
//  Created by 十里 on 2025/2/3.
//

import Foundation

class ResourceManager {
    
    static func binaryPath() -> URL {
        Common.directory.appendingPathComponent("bin").appendingPathComponent("upscayl-bin")
    }
    
    static var modelsURL: URL {
        Common.directory.appendingPathComponent("models")
    }

    static func prepareModels() async throws {
        await ResourceDownloadManager.shared.downloadResourcesIfNeeded()
        
        // Verify resources are available
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: binaryPath().path) else {
            throw NSError(domain: "ResourceManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "upscayl-bin not found"])
        }
        
        guard fileManager.fileExists(atPath: modelsURL.path) else {
            throw NSError(domain: "ResourceManagerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Models directory not found"])
        }
    }
}
