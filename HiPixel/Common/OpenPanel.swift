//
//  OpenPanel.swift
//  HiPixel
//
//  Created by 十里 on 2025/03/11.
//

import AppKit

extension Common {
    static func openPanel(
        from url: URL? = nil,
        message: String = NSLocalizedString("Please select a directory", comment: "Please select a directory"),
        windowTitle: String = "HiPixel",
        _ completion: @escaping (_: URL) -> Void
    ) {
        let openPanel = NSOpenPanel()
        openPanel.message = message
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        if let url = url {
            openPanel.directoryURL = url
        }
        openPanel.prompt = NSLocalizedString("choose", comment: "Please select a directory")
        var window: NSWindow?
        for win in NSApplication.shared.windows {
            if win.title == windowTitle {
                window = win
                break
            }
        }
        if let win = window {
            openPanel.beginSheetModal(for: win) { (result) -> Void in
                if result == .OK, let url = openPanel.url {
                    completion(url)
                } else {
                    Common.logger.info("Open Panel to Get Save Directory failed!")
                }
            }
        } else {
            openPanel.begin { (result) -> Void in
                if result == .OK, let url = openPanel.url {
                    completion(url)
                } else {
                    Common.logger.info("Open Panel to Get Save Directory: canceled!")
                }
            }
        }
    }
}
