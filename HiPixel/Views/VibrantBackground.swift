//
//  VibrantBackground.swift
//  HiPixel
//
//  Created by 十里 on 2024/6/22.
//

import SwiftUI

struct VibrantBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Nothing to update
        nsView.blendingMode = .behindWindow
    }
}
