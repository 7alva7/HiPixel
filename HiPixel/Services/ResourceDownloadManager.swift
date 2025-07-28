//
//  ResourceDownloadManager.swift
//  HiPixel
//
//  Created by 十里 on 2025/7/28.
//

import Foundation
import CryptoKit
import SwiftUI

@MainActor
class ResourceDownloadManager: NSObject, ObservableObject {
    static let shared = ResourceDownloadManager()
    
    @Published var downloadState: DownloadState = .idle
    @Published var downloadProgress: Double = 0
    @Published var downloadSpeed: String = ""
    @Published var currentVersion: String = ""
    @Published var remoteVersion: String = ""
    @Published var errorMessage: String = ""
    
    private let fileManager = FileManager.default
    private var downloadTask: URLSessionDownloadTask?
    
    enum DownloadState: Equatable, CustomStringConvertible {
        case idle
        case checking
        case downloading(String) // resource name
        case installing
        case completed
        case error(String)
        
        var description: String {
            switch self {
            case .idle:
                return "idle"
            case .checking:
                return "checking"
            case .downloading(let resource):
                return "downloading(\(resource))"
            case .installing:
                return "installing"
            case .completed:
                return "completed"
            case .error(let message):
                return "error(\(message))"
            }
        }
    }
    
    private override init() {
        super.init()
        loadCurrentVersion()
        checkResourcesExist()
    }
    
    // MARK: - Public Methods
    
    func checkForUpdates() async {
        // Prevent multiple concurrent downloads
        switch downloadState {
        case .checking, .downloading(_), .installing:
            Common.logger.info("Download already in progress, skipping checkForUpdates")
            return
        default:
            break
        }
        
        downloadState = .checking
        
        do {
            let toolcastInfo = try await ToolcastInfo.fetch()
            remoteVersion = toolcastInfo.version
            
            if needsUpdate(remote: toolcastInfo.version) {
                await downloadResources(toolcastInfo: toolcastInfo)
            } else {
                downloadState = .completed
            }
        } catch {
            downloadState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            Common.logger.error("Failed to check for updates: \(error)")
        }
    }
    
    func downloadResourcesIfNeeded() async {
        // Prevent multiple concurrent downloads
        switch downloadState {
        case .checking, .downloading(_), .installing:
            Common.logger.info("Download already in progress, skipping downloadResourcesIfNeeded")
            return
        default:
            break
        }
        
        // First check if resources exist
        checkResourcesExist()
        
        let binExists = fileManager.fileExists(atPath: binPath.path) && 
                       fileManager.fileExists(atPath: binPath.appendingPathComponent("upscayl-bin").path)
        let modelsExists = fileManager.fileExists(atPath: modelsPath.path) && 
                          hasModelFiles() // Check if models directory has content
        
        if !binExists || !modelsExists {
            Common.logger.info("Resources missing - bin exists: \(binExists), models exists: \(modelsExists)")
            await checkForUpdates()
        } else {
            // Just check for updates without forcing download
            downloadState = .checking
            do {
                let toolcastInfo = try await ToolcastInfo.fetch()
                remoteVersion = toolcastInfo.version
                
                if needsUpdate(remote: toolcastInfo.version) {
                    Common.logger.info("Update available: \(self.currentVersion) -> \(self.remoteVersion)")
                    await downloadResources(toolcastInfo: toolcastInfo)
                } else {
                    downloadState = .completed
                }
            } catch {
                // If we can't check for updates but have local resources, continue
                downloadState = .completed
                Common.logger.error("Failed to check for updates, using local resources: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func downloadResources(toolcastInfo: ToolcastInfo) async {
        do {
            // Download bin.zip
            downloadState = .downloading("bin")
            let binZipPath = try await downloadFile(url: toolcastInfo.bin.url, expectedSHA256: toolcastInfo.bin.sha256)
            
            // Download models.zip
            downloadState = .downloading("models")
            let modelsZipPath = try await downloadFile(url: toolcastInfo.models.url, expectedSHA256: toolcastInfo.models.sha256)
            
            // Install resources
            downloadState = .installing
            try await installResources(binZip: binZipPath, modelsZip: modelsZipPath, version: toolcastInfo.version)
            
            // Clean up
            try fileManager.removeItem(at: binZipPath)
            try fileManager.removeItem(at: modelsZipPath)
            
            downloadState = .completed
            currentVersion = toolcastInfo.version
            
        } catch {
            downloadState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            Common.logger.error("Failed to download resources: \(error)")
        }
    }
    
    private func downloadFile(url: String, expectedSHA256: String) async throws -> URL {
        guard let downloadURL = URL(string: url) else {
            throw ResourceError.invalidURL
        }
        
        let tempURL = Common.directory.appendingPathComponent(UUID().uuidString + ".zip")
        
        return try await withCheckedThrowingContinuation { continuation in
            downloadTask = URLSession.shared.downloadTask(with: downloadURL) { [weak self] localURL, response, error in
                Task { @MainActor in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let localURL = localURL else {
                        continuation.resume(throwing: ResourceError.downloadFailed)
                        return
                    }
                    
                    do {
                        // Move to temp location
                        try self?.fileManager.moveItem(at: localURL, to: tempURL)
                        
                        // Verify SHA256
                        let actualSHA256 = try self?.calculateSHA256(url: tempURL) ?? ""
                        guard actualSHA256 == expectedSHA256 else {
                            try? self?.fileManager.removeItem(at: tempURL)
                            continuation.resume(throwing: ResourceError.checksumMismatch)
                            return
                        }
                        
                        continuation.resume(returning: tempURL)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // Add progress tracking
            downloadTask?.progress.addObserver(self as NSObject, forKeyPath: "fractionCompleted", options: .new, context: nil)
            downloadTask?.resume()
        }
    }
    
    private func installResources(binZip: URL, modelsZip: URL, version: String) async throws {
        // Backup existing resources
        let backupDir = Common.directory.appendingPathComponent("backup")
        try? fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true, attributes: nil)
        
        // Backup bin
        if fileManager.fileExists(atPath: binPath.path) {
            let binBackup = backupDir.appendingPathComponent("bin")
            try? fileManager.removeItem(at: binBackup)
            try? fileManager.moveItem(at: binPath, to: binBackup)
        }
        
        // Backup models
        if fileManager.fileExists(atPath: modelsPath.path) {
            let modelsBackup = backupDir.appendingPathComponent("models")
            try? fileManager.removeItem(at: modelsBackup)
            try? fileManager.moveItem(at: modelsPath, to: modelsBackup)
        }
        
        do {
            // Unzip bin
            try await unzip(file: binZip, to: Common.directory)
            
            // Unzip models
            try await unzip(file: modelsZip, to: Common.directory)
            
            // Make bin executable
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binPath.appendingPathComponent("upscayl-bin").path)
            
            // Save version
            try version.write(to: versionFilePath, atomically: true, encoding: .utf8)
            
            // Remove backup
            try? fileManager.removeItem(at: backupDir)
            
        } catch {
            // Restore backup on failure
            try? fileManager.removeItem(at: binPath)
            try? fileManager.removeItem(at: modelsPath)
            
            let binBackup = backupDir.appendingPathComponent("bin")
            let modelsBackup = backupDir.appendingPathComponent("models")
            
            try? fileManager.moveItem(at: binBackup, to: binPath)
            try? fileManager.moveItem(at: modelsBackup, to: modelsPath)
            
            throw error
        }
    }
    
    private func unzip(file: URL, to destination: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-o", file.path, "-d", destination.path]
            
            do {
                try process.run()
                process.terminationHandler = { process in
                    if process.terminationStatus == 0 {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: ResourceError.unzipFailed)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func calculateSHA256(url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func needsUpdate(remote: String) -> Bool {
        return currentVersion != remote
    }
    
    private func loadCurrentVersion() {
        if let version = try? String(contentsOf: versionFilePath, encoding: .utf8) {
            currentVersion = version.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // No version file found, set as empty for now
            currentVersion = ""
        }
    }
    
    private func checkResourcesExist() {
        let binExists = fileManager.fileExists(atPath: binPath.path) && 
                       fileManager.fileExists(atPath: binPath.appendingPathComponent("upscayl-bin").path)
        let modelsExists = fileManager.fileExists(atPath: modelsPath.path) && hasModelFiles()
        
        Common.logger.info("Resources check: bin=\(binExists), models=\(modelsExists), currentVersion='\(self.currentVersion)'")
        
        if !binExists || !modelsExists {
            downloadState = .idle
            currentVersion = "Not installed"
            Common.logger.info("Resources missing - setting currentVersion to 'Not installed'")
        } else if currentVersion.isEmpty || currentVersion == "Not installed" {
            // Resources exist but no version info, we still need to check for updates
            downloadState = .idle
            currentVersion = "Unknown"
            Common.logger.info("Resources exist but version unknown")
        } else {
            downloadState = .completed
            Common.logger.info("Resources exist with version: \(self.currentVersion)")
        }
    }
    
    private func hasModelFiles() -> Bool {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: modelsPath.path)
            return !contents.isEmpty && contents.contains { $0.hasSuffix(".bin") || $0.hasSuffix(".param") }
        } catch {
            return false
        }
    }
    
    // MARK: - Progress Observation
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "fractionCompleted" {
            Task { @MainActor in
                if let progress = downloadTask?.progress {
                    downloadProgress = progress.fractionCompleted
                    
                    // Calculate download speed
                    let bytesReceived = progress.completedUnitCount
                    let timeElapsed = progress.estimatedTimeRemaining ?? 0
                    
                    if timeElapsed > 0 {
                        let speed = Double(bytesReceived) / timeElapsed
                        downloadSpeed = ByteCountFormatter().string(fromByteCount: Int64(speed)) + "/s"
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var binPath: URL {
        Common.directory.appendingPathComponent("bin")
    }
    
    private var modelsPath: URL {
        Common.directory.appendingPathComponent("models")
    }
    
    private var versionFilePath: URL {
        Common.directory.appendingPathComponent("version.txt")
    }
}

// MARK: - ResourceError
enum ResourceError: LocalizedError {
    case invalidURL
    case downloadFailed
    case checksumMismatch
    case unzipFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid download URL"
        case .downloadFailed:
            return "Download failed"
        case .checksumMismatch:
            return "File checksum verification failed"
        case .unzipFailed:
            return "Failed to extract files"
        }
    }
}
