//
//  ResourceManager.swift
//  HiPixel
//
//  Created by 十里 on 2025/2/3.
//

import Foundation

class ResourceManager {
    static func binaryPath() -> URL {
        guard let url = Bundle.main.url(
            forResource: "upscayl-bin",
            withExtension: nil
        ) else {
            fatalError("Missing upscayl-bin in bundle")
        }
        return url
    }
    
    static var modelsURL: URL {
        Common.directory.appendingPathComponent("models")
    }

    static func prepareModels() throws {
        let fileManager = FileManager.default
        let modelsZipURL = Bundle.main.url(forResource: "models", withExtension: "zip")!
        let destinationURL = Common.directory.appendingPathComponent("models")
        
        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            
            let process = Process()
            process.launchPath = "/usr/bin/unzip"
            process.arguments = ["-o", modelsZipURL.path, "-d", Common.directory.path]
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                throw NSError(domain: "ResourceManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to unzip models"])
            }
        }
    }
}
