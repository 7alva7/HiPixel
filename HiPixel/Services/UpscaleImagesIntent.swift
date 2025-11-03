//
//  UpscaleImagesIntent.swift
//  HiPixel
//
//  Created for AppIntents support
//

import AppIntents
import Foundation
import SwiftUI

struct UpscaleImagesIntent: AppIntent {
    static var title: LocalizedStringResource = "Upscale Images"
    static var description = IntentDescription("Upscale images using AI with HiPixel.")

    @Parameter(title: "Files", description: "Image files or folders to upscale")
    var files: [IntentFile]

    @Parameter(title: "Image Scale", description: "Upscaling factor (multiplier)", default: 4.0)
    var imageScale: Double?

    @Parameter(title: "Save Format", description: "Output image format")
    var saveImageAs: ImageFormatEnum?

    @Parameter(title: "Double Upscayl", description: "Enable double upscaling (upscale twice)", default: false)
    var doubleUpscayl: Bool?

    @Parameter(title: "Enable TTA", description: "Enable Test Time Augmentation for better quality", default: false)
    var enableTTA: Bool?

    @Parameter(title: "Compression Level", description: "Compression level (0-99)")
    var imageCompression: Int?

    @Parameter(
        title: "Enable Zipic Compression", description: "Enable Zipic compression (requires Zipic app)", default: false)
    var enableZipicCompression: Bool?

    @Parameter(title: "Custom Output Folder", description: "Custom folder path for output images")
    var saveOutputFolder: String?

    @Parameter(title: "GPU ID", description: "GPU ID to use for processing")
    var gpuID: String?

    @Parameter(title: "Custom Tile Size", description: "Custom tile size for processing (0 uses default)")
    var customTileSize: Int?

    @Parameter(title: "Upscayl Model", description: "Built-in AI model to use")
    var upscaylModel: UpscaylModelEnum?

    @Parameter(title: "Selected Custom Model", description: "Custom model name to use")
    var selectedCustomModel: String?

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$files
            \.$imageScale
            \.$saveImageAs
            \.$doubleUpscayl
            \.$enableTTA
            \.$imageCompression
            \.$enableZipicCompression
            \.$saveOutputFolder
            \.$gpuID
            \.$customTileSize
            \.$upscaylModel
            \.$selectedCustomModel
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Convert IntentFile to URLs
        let urls = files.compactMap { file -> URL? in
            // Prefer fileURL if available
            if let url = file.fileURL, url.isFileURL {
                return url
            }
            // Fallback: try to write data to temporary file if it's image data
            let data = file.data
            if !data.isEmpty {
                // Check if data looks like image data by checking first bytes
                let imageSignatures: [Data] = [
                    Data([0x89, 0x50, 0x4E, 0x47]),  // PNG
                    Data([0xFF, 0xD8, 0xFF]),  // JPEG
                ]
                if imageSignatures.contains(where: { data.prefix($0.count) == $0 }) {
                    let tmp = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("jpg")
                    try? data.write(to: tmp)
                    return tmp
                }
            }
            return nil
        }

        guard !urls.isEmpty else {
            return .result(dialog: IntentDialog(stringLiteral: String(localized: "No valid image files provided.")))
        }

        // Validate URLs - check if they exist and are images or folders
        let validURLs = urls.compactMap { url -> URL? in
            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            guard url.isImageFile || url.isFile(ofTypes: [.folder]) else {
                return nil
            }
            return url
        }

        guard !validURLs.isEmpty else {
            return .result(
                dialog: IntentDialog(stringLiteral: String(localized: "No valid image files or folders found.")))
        }

        // Build UpscaylOptions from parameters
        let options = buildOptions()

        // Collect all image URLs to process
        var allImageURLs: [URL] = []
        for url in validURLs {
            if url.hasDirectoryPath {
                allImageURLs.append(contentsOf: url.imageContents)
            } else {
                allImageURLs.append(url)
            }
        }

        guard !allImageURLs.isEmpty else {
            return .result(
                dialog: IntentDialog(stringLiteral: String(localized: "No valid image files or folders found.")))
        }

        // Process images sequentially and wait for completion
        var successCount = 0
        var failedCount = 0

        for imageURL in allImageURLs {
            guard imageURL.fileSize > 0 else { continue }

            let item = UpscaylDataItem(imageURL)

            // Process each image and wait for completion using continuation
            let result = await withCheckedContinuation { (continuation: CheckedContinuation<URL?, Never>) in
                Upscayl.process(
                    item,
                    progressHandler: { _, _ in
                        // Progress updates can be handled here if needed
                    },
                    completedHandler: { outputURL in
                        continuation.resume(returning: outputURL)
                    },
                    options: options
                )
            }

            if result != nil {
                successCount += 1
            } else {
                failedCount += 1
            }
        }

        // Return result based on processing outcome
        if failedCount == 0 {
            let message = String(localized: "Successfully processed %lld file(s).")
            return .result(dialog: IntentDialog(stringLiteral: String(format: message, successCount)))
        } else {
            let message = String(localized: "Processed %lld file(s), %lld succeeded, %lld failed.")
            return .result(
                dialog: IntentDialog(
                    stringLiteral: String(format: message, successCount + failedCount, successCount, failedCount)))
        }
    }

    private func buildOptions() -> UpscaylOptions {
        var options = UpscaylOptions()

        if let imageScale = imageScale {
            options.imageScale = imageScale
        }

        if let saveImageAs = saveImageAs {
            options.saveImageAs = saveImageAs.toImageFormat()
        }

        if let doubleUpscayl = doubleUpscayl {
            options.doubleUpscayl = doubleUpscayl
        }

        if let enableTTA = enableTTA {
            options.enableTTA = enableTTA
        }

        if let imageCompression = imageCompression {
            options.imageCompression = imageCompression
        }

        if let enableZipicCompression = enableZipicCompression {
            options.enableZipicCompression = enableZipicCompression
        }

        if let saveOutputFolder = saveOutputFolder {
            options.saveOutputFolder = saveOutputFolder
            options.enableSaveOutputFolder = true
        }

        if let gpuID = gpuID {
            options.gpuID = gpuID
        }

        if let customTileSize = customTileSize {
            options.customTileSize = customTileSize
        }

        if let upscaylModel = upscaylModel {
            options.upscaylModel = upscaylModel.toUpscaylModel()
        }

        if let selectedCustomModel = selectedCustomModel {
            options.selectedCustomModel = selectedCustomModel
        }

        return options
    }
}

// MARK: - Enum Types for AppIntent Parameters

enum ImageFormatEnum: String, AppEnum {
    case png = "PNG"
    case jpg = "JPG"
    case webp = "WEBP"
    case original = "Original"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Image Format"
    static var caseDisplayRepresentations: [ImageFormatEnum: DisplayRepresentation] = [
        .png: "PNG",
        .jpg: "JPG",
        .webp: "WEBP",
        .original: "Original",
    ]

    func toImageFormat() -> HiPixelConfiguration.ImageFormat {
        switch self {
        case .png: return .png
        case .jpg: return .jpg
        case .webp: return .webp
        case .original: return .original
        }
    }
}

enum UpscaylModelEnum: String, AppEnum {
    case standard = "upscayl-standard-4x"
    case lite = "upscayl-lite-4x"
    case highFidelity = "high-fidelity-4x"
    case digitalArt = "digital-art-4x"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Upscayl Model"
    static var caseDisplayRepresentations: [UpscaylModelEnum: DisplayRepresentation] = [
        .standard: "Standard",
        .lite: "Lite",
        .highFidelity: "High Fidelity",
        .digitalArt: "Digital Art",
    ]

    func toUpscaylModel() -> HiPixelConfiguration.UpscaylModel {
        switch self {
        case .standard: return .Upscayl_Standard
        case .lite: return .Upscayl_Lite
        case .highFidelity: return .High_Fidenlity
        case .digitalArt: return .Digital_Art
        }
    }
}

struct HiPixelShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        let shortcut = AppShortcut(
            intent: UpscaleImagesIntent(),
            phrases: [
                "Upscale images with \(.applicationName)",
                "Process images with \(.applicationName)",
            ],
            shortTitle: "Upscale Images",
            systemImageName: "photo.stack"
        )
        return [shortcut]
    }
}
