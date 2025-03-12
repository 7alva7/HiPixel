//
//  AboutWindowController.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/22.
//

import SwiftUI

class AboutWindowController: NSWindowController {
    
    static let shared = AboutWindowController()
    
    convenience init() {
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)
        let newWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 0),
                                 styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                                 backing: .buffered,
                                 defer: false)
        newWindow.contentView = hostingController.view
        newWindow.isMovableByWindowBackground = true
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        
        // Add this to make the window size fit the content
        newWindow.setContentSize(hostingController.view.fittingSize)
        
        newWindow.center()
        
        self.init(window: newWindow)
    }
}
