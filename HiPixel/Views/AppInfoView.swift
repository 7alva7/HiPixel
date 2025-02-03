//
//  AppInfoView.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/23.
//

import SwiftUI

struct AppInfoView: View {
    var body: some View {
        HStack {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(AppInfo.appName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Version \(AppInfo.version) (\(AppInfo.build))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("AI lmage Upscaler for macOS\nBased on **[Upscayl](https://upscayl.org/)**")
                    .lineSpacing(4)
                    .opacity(0.8)
                    .frame(height: 36)
            }
        }
    }
}

#Preview {
    AppInfoView()
}
