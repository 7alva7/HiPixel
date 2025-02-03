//
//  Public.swift
//  HiPixel
//
//  Created by 十里 on 2024/6/21.
//

import os
import SwiftUI
import UniformTypeIdentifiers

enum Common {
    
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
    
    static let logger = Logger(
        subsystem: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "cn.smslit.timeGo",
        category: "main"
    )
    
    static func timeString(from seconds: Int, simplified: Bool = false) -> String {
        let minutes = seconds % 3600 / 60
        let hours = seconds / 3600
        let remainingSeconds = seconds % 60
        if hours == 0 && simplified {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
    
    static var isPanelOpen: Bool = false
    static func upscaleWithPanel(completionHandler handler: @escaping ([URL]) -> Void) {
        if isPanelOpen {
            return
        }
        isPanelOpen = true
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.jpeg, .png, .webP, .folder]
        panel.begin { result in
            if result == NSApplication.ModalResponse.OK {
                Common.logger.info("\(panel.urls)")
                handler(panel.urls)
            }
            isPanelOpen = false
        }
    }
    
    static func getImageURLs(at url: URL) -> [URL] {
        
        let fileManager = FileManager.default
        var urls = [URL]()
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            
            for childURL in contents {
                if childURL.hasDirectoryPath {
                    urls.append(contentsOf: getImageURLs(at: childURL))
                } else if childURL.isImageFile {
                    urls.append(childURL)
                }
            }
        } catch {
            Common.logger.error(("Failed to retrieve directory contents: \(error)"))
        }
        return urls
    }
    
    static func fileExists(at url: URL) -> Bool {
        // 尝试下载 iCLoud 的文件
        var count = 0
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
            } catch {
                Common.logger.error("sycn \(url.path) failed: \(error)")
            }
        } else {
            return true
        }
        while !FileManager.default.fileExists(atPath: url.path) {
            count += 1
            if count > 10 {
                break
            }
            Thread.sleep(forTimeInterval: 1)
        }
        
        return FileManager.default.fileExists(atPath: url.path)
    }
    
}

enum AppInfo {
    static let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "HiPixel"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
