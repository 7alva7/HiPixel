//
//  ResourceDownloadSheet.swift
//  HiPixel
//
//  Created by 十里 on 2025/7/28.
//

import SwiftUI

struct ResourceDownloadSheet: View {
    @StateObject private var downloadManager = ResourceDownloadManager.shared
    @State private var canDismiss = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                Text("Download Dependencies")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("HiPixel needs to download AI models and processing tools to function properly.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Download progress
            VStack(spacing: 12) {
                switch downloadManager.downloadState {
                case .idle:
                    ProgressView()
                        .scaleEffect(0.5)
                    
                case .checking:
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Checking for latest version...")
                        .font(.body)
                    
                case .downloading(_):
                    ProgressView(value: downloadManager.downloadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        Text("\(Int(downloadManager.downloadProgress * 100))%")
                        Spacer()
                        if !downloadManager.downloadSpeed.isEmpty {
                            Text(downloadManager.downloadSpeed)
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                    
                case .installing:
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Installing...")
                        .font(.body)
                    
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    Text("Download Complete!")
                        .font(.headline)
                    
                    Button("Continue") {
                        canDismiss = true
                    }
                    .buttonStyle(.gradient(configuration: .primary))
                    
                    .onAppear {
                        // Auto dismiss after 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            canDismiss = true
                        }
                    }
                    
                case .error(let message):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                    Text("Download Failed")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Button("Retry") {
                            Task {
                                await downloadManager.checkForUpdates()
                            }
                        }
                        .buttonStyle(.gradient(configuration: .primary))
                        
                        Button("Skip for Now") {
                            canDismiss = true
                        }
                        .buttonStyle(.gradient(configuration: .danger))
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(.regularMaterial)
        .interactiveDismissDisabled(!canDismiss)
        .onAppear {
            // Start download immediately when sheet appears
            if downloadManager.downloadState == .idle {
                Task {
                    await downloadManager.checkForUpdates()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isErrorState(_ state: ResourceDownloadManager.DownloadState) -> Bool {
        if case .error(_) = state {
            return true
        }
        return false
    }
}

// MARK: - Preview
#Preview {
    ResourceDownloadSheet()
}
