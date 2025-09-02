//
//  Upscayl.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/31.
//

import SwiftUI

struct CommandResult: CustomStringConvertible {
    let output: String
    let error: Process.TerminationReason
    let status: Int32

    var description: String {
        "error:\(error.rawValue), output:\(output), status:\(status)"
    }
}
enum Upscayl {
    // MARK: - Types

    struct CommandResult: CustomStringConvertible {
        let output: String
        let error: Process.TerminationReason
        let status: Int32

        var description: String {
            "error:\(error.rawValue), output:\(output), status:\(status)"
        }
    }

    // MARK: - Constants

    private enum Constants {
        static let progressPrefix = "UPSCAYL_PROGRESS:"
    }

    // MARK: - Public Methods

    static func process(
        _ item: UpscaylDataItem,
        progressHandler: @escaping (_ progress: Double) -> Void,
        completedHandler: @escaping (_ url: URL?) -> Void
    ) {
        let arguments = makeArguments(for: item)
        let formatStr = determineFormatString(for: item)
        let newURL = makeOutputURL(for: item, ext: formatStr)
        Common.logger.debug("\(arguments)")
        if FileManager.default.fileExists(atPath: newURL.path)
            && !(HiPixelConfiguration.shared.overwritePreviousUpscale)
        {
            completedHandler(newURL)
            return
        }
        let result = run(arguments: arguments, progressHandler: progressHandler)

        // Handle compression if needed
        if result.status == 0 && HiPixelConfiguration.shared.imageCompression > 0 {
            if HiPixelConfiguration.shared.enableZipicCompression
                && AppInstallationChecker.isAppInstalled(bundleIdentifier: "studio.5km.zipic")
            {
                // Use Zipic for compression
                let saveDir =
                    HiPixelConfiguration.shared.enableSaveOutputFolder
                    ? URL(string: HiPixelConfiguration.shared.saveOutputFolder ?? "")?.standardizedFileURL : nil
                ZipicCompressor.compress(
                    url: newURL,
                    saveDirectory: saveDir,
                    format: formatStr,
                    level: Double(HiPixelConfiguration.shared.imageCompression) / 16.5  // Convert 0-99 to 1-6 range
                )
            }
        }

        // Preserve metadata from original image to processed image if processing succeeded
        if result.status == 0 {
            EXIFMetadataManager.compareAndCopyMetadata(from: item.url, to: newURL)
        }

        completedHandler(result.status == 0 ? newURL : nil)
    }

    static let semaphore = DispatchSemaphore(value: 1)

    static func process(
        _ urls: [URL],
        by data: UpscaylData
    ) {
        if urls.isEmpty { return }
        let group = DispatchGroup()

        guard let first = urls.first else { return }

        let baseDir: URL = first.deletingLastPathComponent()
        var saveDir = baseDir

        if HiPixelConfiguration.shared.enableSaveOutputFolder,
            let folderPath = HiPixelConfiguration.shared.saveOutputFolder,
            let folderURL = URL(string: folderPath)
        {
            saveDir = folderURL
            do {
                try FileManager.default.createDirectory(at: saveDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Common.logger.error("Failed to create directory at \(baseDir), \(error)")
            }
        }

        struct SignURL {
            let url: URL
            let dirURL: URL?
        }

        var signURLs: [SignURL] = []
        for url in urls {
            if url.hasDirectoryPath {
                let imageURLs = url.imageContents
                let _signURLs = imageURLs.map { SignURL(url: $0, dirURL: url) }
                signURLs.append(contentsOf: _signURLs)
            } else {
                if !url.isImageFile { continue }
                signURLs.append(SignURL(url: url, dirURL: nil))
            }
        }

        if signURLs.isEmpty { return }

        let operationQueue = QueueManager.shared.allocate(count: signURLs.count)

        for signURL in signURLs {
            let imageURL = signURL.url
            let url = signURL.dirURL

            if imageURL.fileSize == .zero {
                continue
            }

            let operation = BlockOperation {
                var _saveDir = saveDir

                if url != nil {
                    let baseURL = url!.deletingLastPathComponent()
                    let relativePath = imageURL.path
                        .replacingOccurrences(of: baseURL.path, with: "")
                        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    _saveDir = baseDir.appendingPathComponent(relativePath).deletingLastPathComponent()

                    let fileManager = FileManager.default

                    do {
                        try fileManager.createDirectory(
                            at: _saveDir, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        Common.logger.error("An error occurred: \(error)")
                    }
                }

                /// Check if it has been synced from iCloud
                if !imageURL.exists {
                    return
                }

                var item = UpscaylDataItem(imageURL)
                if let nsImage = NSImage(contentsOf: imageURL) {
                    item.size = nsImage.pixelSize
                    item.newSize = CGSize(
                        width: item.size.width * HiPixelConfiguration.shared.imageScale,
                        height: item.size.height * HiPixelConfiguration.shared.imageScale
                    )
                    if let thumbnail = nsImage.thumbnail(with: 128).saveAtThumbnailDirectory(as: item.fileName) {
                        item.thumbnail = thumbnail
                    } else {
                        item.thumbnail = imageURL
                    }
                }

                DispatchQueue.main.async {
                    data.append(item)
                    data.selectedItem = item
                }

                Upscayl.process(
                    item,
                    progressHandler: { progress in
                        item.progress = progress
                        DispatchQueue.main.async {
                            data.update(item)
                            if data.selectedItem?.url == item.url {
                                data.selectedItem = item
                            }
                        }
                    },
                    completedHandler: { url in
                        if let url = url {
                            // Preserve metadata from original image to processed image
                            EXIFMetadataManager.compareAndCopyMetadata(from: imageURL, to: url)
                            
                            item.newURL = url
                            item.newFileSize = url.fileSize
                            item.timeInterval = Date.now.timeIntervalSince(item.startAt)
                            item.state = .success
                            Common.logger.debug("\(item.newURL)")
                        } else {
                            item.state = .failed
                        }
                        DispatchQueue.main.async {
                            data.update(item)
                            data.selectedItem = item
                        }
                    }
                )
            }

            operation.completionBlock = {
                group.leave()
            }

            group.enter()
            operationQueue.addOperation(operation)
        }

        group.notify(queue: DispatchQueue.main) {
            if HiPixelConfiguration.shared.notification != .None {
                NotificationX.push(
                    message: String(
                        format: NSLocalizedString("Upscale completed: %d images", comment: ""), signURLs.count))
            }
        }
    }

    // MARK: - Private Methods

    private static func run(
        arguments: [String],
        progressHandler: ((Double) -> Void)? = nil
    ) -> CommandResult {
        let pipe = Pipe()
        let process = configureProcess(with: arguments, pipe: pipe)
        let outputData = executeProcess(process, pipe: pipe, progressHandler: progressHandler)

        let output = String(data: outputData, encoding: .utf8)
        let result = CommandResult(
            output: output ?? "",
            error: process.terminationReason,
            status: process.terminationStatus
        )

        logErrorIfNeeded(result: result, arguments: arguments)
        return result
    }

    private static func configureProcess(with arguments: [String], pipe: Pipe) -> Process {
        let process = Process()
        process.executableURL = URL(
            fileURLWithPath: ResourceManager.binaryPath().path,
            isDirectory: false,
            relativeTo: NSRunningApplication.current.bundleURL
        )
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        return process
    }

    private static func executeProcess(
        _ process: Process,
        pipe: Pipe,
        progressHandler: ((Double) -> Void)?
    ) -> Data {
        var outputData = Data()

        pipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            if !data.isEmpty {
                outputData.append(data)
                handleProcessOutput(data, progressHandler: progressHandler)
            }
            outputData.append(handler.availableData)
        }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            Common.logger.error("command: upscayl-bin \(process.arguments?.joined(separator: " ") ?? ""), \(error)")
        }

        pipe.fileHandleForReading.readabilityHandler = nil
        try? pipe.fileHandleForReading.close()

        return outputData
    }

    private static func handleProcessOutput(_ data: Data, progressHandler: ((Double) -> Void)?) {
        guard let str = String(data: data, encoding: .utf8) else { return }

        Common.logger.info("\(str)")
        str.components(separatedBy: .newlines).forEach { line in
            if line.contains("%") {
                extractAndUpdateProgress(from: line, handler: progressHandler)
            }
        }
    }

    private static func extractAndUpdateProgress(from line: String, handler: ((Double) -> Void)?) {
        DispatchQueue.main.async {
            let percentStr = line.replacingOccurrences(of: "%", with: "")
            if let percent = Double(percentStr) {
                handler?(percent)
            }
        }
    }

    private static func makeArguments(for item: UpscaylDataItem) -> [String] {
        let formatString = determineFormatString(for: item)
        let outputURL = makeOutputURL(for: item, ext: formatString)
        var args = [
            "-i", item.url.path,
            "-o", outputURL.path,
            "-s", "\(Int(HiPixelConfiguration.shared.imageScale))",
            "-m", ResourceManager.modelsURL.path,
            "-n", HiPixelConfiguration.shared.upscaleModel.id,
            "-f", formatString,
        ]

        // Only add compression if not using Zipic
        if HiPixelConfiguration.shared.imageCompression > 0 && !HiPixelConfiguration.shared.enableZipicCompression {
            args.append(contentsOf: ["-c", "\(HiPixelConfiguration.shared.imageCompression)"])
        }

        if HiPixelConfiguration.shared.gpuID != "" {
            args.append(contentsOf: ["-g", HiPixelConfiguration.shared.gpuID])
        }

        if HiPixelConfiguration.shared.customTileSize != 0 {
            args.append(contentsOf: ["-t", "\(HiPixelConfiguration.shared.customTileSize)"])
        }

        if HiPixelConfiguration.shared.enableTTA {
            args.append("-x")
        }

        return args
    }

    private static func determineFormatString(for item: UpscaylDataItem) -> String {
        switch HiPixelConfiguration.shared.saveImageAs {
        case .png: return "png"
        case .jpg: return "jpeg"
        case .webp: return "webp"
        case .original: return item.url.imageIdentifier ?? "png"
        }
    }

    private static func makeOutputURL(for item: UpscaylDataItem, ext: String) -> URL {
        var url = item.url
        if HiPixelConfiguration.shared.enableSaveOutputFolder,
            let saveFolder = HiPixelConfiguration.shared.saveOutputFolder,
            let baseDir = URL(string: "file://" + saveFolder)
        {
            url = baseDir.appendingPathComponent(url.lastPathComponent)
        }

        let postfix =
            "_hipixel_\(Int(HiPixelConfiguration.shared.imageScale))x_\(HiPixelConfiguration.shared.upscaleModel.id)"
        return url.appendingPostfix(postfix).changingPathExtension(to: ext)
    }

    private static func logErrorIfNeeded(result: CommandResult, arguments: [String]) {
        if result.status != 0 {
            Common.logger.error("command: upscayl-bin \(arguments.joined(separator: " ")), \(result)")
        }
    }
}
