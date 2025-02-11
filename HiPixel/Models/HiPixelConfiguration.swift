//
//  Configuration.swift
//  HiPixel
//
//  Created by 十里 on 2024/6/22.
//

import SwiftUI

struct HiPixelConfiguration {
    
    static var shared = HiPixelConfiguration()
    
    enum Keys {
        static let FirstLaunch = "HIPixel-FirstLaunch"
        static let ColorScheme = "HIPixel-ColorScheme"
        static let NotificationMode = "HIPixel-NotificationMode"
        static let SaveImageAs = "HIPixel-SaveImageAs"
        static let ImageScale = "HIPixel-ImageScale"
        static let ImageCompression = "HIPixel-ImageCompression"
        static let EnableZipicCompression = "HiPixel-EnableZipicCompression"
        static let EnableSaveOutputFolder = "HIPixel-EnableSaveOutputFolder"
        static let SaveOutputFolder = "HIPixel-SaveOutputFolder"
        static let OverwritePreviousUpscale = "HIPixel-OverwritePreviousUpscale"
        static let GPUID = "HIPixel-GPUID"
        static let CustomTileSize = "HIPixel-CustomTileSize"
        static let CustomModelsFolder = "HIPixel-CustomModelsFolder"
        static let UpscaylModel = "HIPixel-UpscaylModel"
        static let UpscaylModelVersion: String = "HIPixel-UpscaylModel-Version"
        static let DoubleUpscayl = "HIPixel-DoubleUpscayl"
        static let SelectedAppIcon = "HIPixel-AppIconSelected"
    }
    
    enum ColorScheme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
        
        var icon: String {
            switch self {
            case .light:
                return "sun.max.fill"
            case .dark:
                return "moon.fill"
            case .system:
                return "circle.righthalf.filled"
            }
        }
        
        var localized: String {
            switch self {
            case .light:
                return NSLocalizedString("Light", comment: "")
            case .dark:
                return NSLocalizedString("Dark", comment: "")
            case .system:
                return NSLocalizedString("System", comment: "")
            }
        }
        
        static func change(to mode: ColorScheme) {
            @AppStorage(Keys.ColorScheme)
            var colorScheme: ColorScheme = .system
            
            colorScheme = mode
            
            switch mode {
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case .system:
                NSApp.appearance = nil
            }
        }
    }
    
    enum NotificationMode: Int, Codable, CaseIterable {
        case None, HiPixel, Notch, System
        
        var localized: String {
            switch self {
            case .None:
                return NSLocalizedString("Disable Notification", comment: "")
            case .HiPixel:
                return NSLocalizedString("HiPixel Notification", comment: "")
            case .Notch:
                return NSLocalizedString("Notch Notification", comment: "")
            case .System:
                return NSLocalizedString("System Notification", comment: "")
            }
        }
    }
    
    enum ImageFormat: String, Codable, CaseIterable {
        case png = "PNG"
        case jpg = "JPG"
        case webp = "WEBP"
        case original = "Original"
        
        var localized: String {
            switch self {
            case .png:
                return NSLocalizedString("PNG", comment: "")
            case .jpg:
                return NSLocalizedString("JPG", comment: "")
            case .webp:
                return NSLocalizedString("WEBP", comment: "")
            case .original:
                return NSLocalizedString("Original", comment: "")
            }
        }
    }
    
    enum UpscaylModel: String, Codable, CaseIterable {
        case Upscayl_Standard = "upscayl-standard-4x"
        case Upscayl_Lite = "upscayl-lite-4x"
        case High_Fidenlity = "high-fidelity-4x"
        case Digital_Art = "digital-art-4x"
        
        static let description: LocalizedStringKey = "UpscaylModel description"
        
        var id: String {
            self.rawValue
        }
        
        var text: String {
            switch self {
            case .Upscayl_Standard:
                return "Standard".localized
            case .Upscayl_Lite:
                return "Lite".localized
            case .High_Fidenlity:
                return "High Fidelity".localized
            case .Digital_Art:
                return "Digital Art".localized
            }
        }
        
        func isAvaliable(at directory: URL) -> Bool {
            let binURL = directory.appendingPathComponent("\(self.id).bin")
            let paramURL = directory.appendingPathComponent("\(self.id).param")
            let fileManager = FileManager.default
            return fileManager.fileExists(atPath: binURL.path) && fileManager.fileExists(atPath: paramURL.path)
        }
    }
    
    enum AppIcon: String, CaseIterable {
        case primary = "AppIcon"
        case secondary = "SecondaryAppIcon"
        
        var displayName: LocalizedStringKey {
            switch self {
            case .primary:
                return "Designed by zaotang.xyz"
            case .secondary:
                return "Designed by @okooo5km"
            }
        }
        
        var previewImage: NSImage? {
            NSImage(named: self.rawValue)
        }
    }
    
    @AppStorage(Keys.FirstLaunch)
    var firstLaunch: Bool = true
    
    @AppStorage(Keys.ColorScheme)
    var colorScheme: ColorScheme = .system
    
    @AppStorage(Keys.NotificationMode)
    var notification: NotificationMode = .None
    
    @AppStorage(Keys.SaveImageAs)
    var saveImageAs: ImageFormat = .original
    
    @AppStorage(Keys.ImageScale)
    var imageScale: Double = 4.0
    
    @AppStorage(Keys.ImageCompression)
    var imageCompression: Int = 0
    
    @AppStorage(Keys.EnableZipicCompression)
    var enableZipicCompression: Bool = false
    
    @AppStorage(Keys.EnableSaveOutputFolder)
    var enableSaveOutputFolder: Bool = false
    
    @AppStorage(Keys.SaveOutputFolder)
    var saveOutputFolder: String?
    
    @AppStorage(Keys.OverwritePreviousUpscale)
    var overwritePreviousUpscale: Bool = true
    
    @AppStorage(Keys.GPUID)
    var gpuID: String = ""
    
    @AppStorage(Keys.CustomTileSize)
    var customTileSize: Int = 0
    
    @AppStorage(Keys.CustomModelsFolder)
    var customModelsFolder: String?
    
    @AppStorage(Keys.DoubleUpscayl)
    var doubleUpscayl: Bool = false
    
    @AppStorage(Keys.UpscaylModel)
    var upscaleModel: UpscaylModel = .Upscayl_Standard
    
    @AppStorage(Keys.UpscaylModelVersion)
    var upscaleModelVersion: String = "2.14.0"
    
    func reset() {
        saveImageAs = .png
        imageScale = 4.0
        imageCompression = 0
        enableSaveOutputFolder = false
        enableZipicCompression = false
        saveOutputFolder = nil
        overwritePreviousUpscale = true
        gpuID = ""
        customTileSize = 0
        customModelsFolder = nil
        doubleUpscayl = false
        upscaleModel = .Upscayl_Standard
    }
}
