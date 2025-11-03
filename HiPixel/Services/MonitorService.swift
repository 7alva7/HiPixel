//
//  MonitorService.swift
//  HiPixel
//
//  Created by 十里 on 2025/03/11.
//

import SwiftUI
import FSWatcher

class MonitorService: ObservableObject {
    static let shared = MonitorService()
    
    private init() {
        directoryWatcher.delegate = self
    }

    static let monitorItemsKey = "monitorItems"

    @Published var items: [MonitorItem] = []

    private let directoryWatcher = FSWatcher.MultiDirectoryWatcher()
    private var whiteList = [URL: Set<URL>]()

    func load() {
        if let data = UserDefaults.standard.data(forKey: Self.monitorItemsKey) {
            if let items = try? JSONDecoder().decode([MonitorItem].self, from: data) {
                self.items = items
                for item in items {
                    let images = item.url.imageContents
                    whiteList[item.url] = Set(images)
                }
                if !items.isEmpty {
                    updateMonitoring()
                }
            }
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.monitorItemsKey)
        }
    }

    func add(_ item: MonitorItem) {
        if contains(item) {
            return
        }
        items.append(item)
        whiteList[item.url] = Set(item.url.imageContents)
        save()
        updateMonitoring()
    }

    func remove(_ item: MonitorItem) {
        whiteList.removeValue(forKey: item.url)
        items.removeAll(where: { $0.id == item.id })
        save()
        updateMonitoring()
    }

    func removeAll() {
        directoryWatcher.stopAllWatching()
        items.removeAll()
        whiteList.removeAll()
        save()
    }

    func update(_ item: MonitorItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let origin = items[index]
            items[index] = item
            whiteList.removeValue(forKey: origin.url)
            whiteList[item.url] = Set(item.url.imageContents)
            save()
            updateMonitoring()
        }
    }

    func contains(_ item: MonitorItem) -> Bool {
        return items.contains(where: { $0.url == item.url })
    }

    private func startMonitor() {
        let enabledDirectories = items.filter { $0.enabled }.map { $0.url }
        directoryWatcher.startWatching(directories: enabledDirectories)
    }

    private func stopMonitor() {
        directoryWatcher.stopAllWatching()
    }
    
    private func updateMonitoring() {
        let enabledDirectories = items.filter { $0.enabled }.map { $0.url }
        if enabledDirectories.isEmpty {
            directoryWatcher.stopAllWatching()
        } else {
            directoryWatcher.startWatching(directories: enabledDirectories)
        }
    }
    
    private func processDirectoryChange(at changedPath: URL) {
        guard let item = items.first(where: { $0.url == changedPath && $0.enabled }) else {
            return
        }
        
        let images = Set(changedPath.imageContents)
        let whiteList = self.whiteList[item.url] ?? []
        let targetImages = Array(images.subtracting(whiteList))
        
        guard !targetImages.isEmpty else {
            // Update whitelist when no processing tasks are running
            if UpscaylData.shared.items.filter({ $0.state == .processing }).isEmpty {
                self.whiteList[item.url] = images
            }
            return
        }
        
        // Update whitelist with new images
        self.whiteList[item.url]?.formUnion(targetImages)
        
        // Add predicted output image names to whitelist
        let compressedImages = targetImages.map {
            return Self.makeOutputURL(for: $0)
        }
        self.whiteList[item.url]?.formUnion(Set(compressedImages))
        
        // Trigger upscaling
        Upscayl.process(targetImages, by: UpscaylData.shared, source: .automated)
    }

    private static func makeOutputURL(for url: URL) -> URL {
        var newURL = url

        let ext = {
            switch HiPixelConfiguration.shared.saveImageAs {
            case .png: return "png"
            case .jpg: return "jpeg"
            case .webp: return "webp"
            case .original: return url.imageIdentifier ?? "png"
            }
        }()

        if HiPixelConfiguration.shared.enableSaveOutputFolder,
            let saveFolder = HiPixelConfiguration.shared.saveOutputFolder,
            let baseDir = URL(string: "file://" + saveFolder)
        {
            newURL = baseDir.appendingPathComponent(url.lastPathComponent)
        }

        let postfix =
            "_hipixel_\(Int(HiPixelConfiguration.shared.imageScale))x_\(HiPixelConfiguration.shared.upscaleModel.id)"
        return newURL.appendingPostfix(postfix).changingPathExtension(to: ext)
    }
}

// MARK: - DirectoryWatcherDelegate
extension MonitorService: FSWatcher.DirectoryWatcherDelegate {
    func directoryDidChange(at url: URL) {
        DispatchQueue.main.async { [weak self] in
            self?.processDirectoryChange(at: url)
        }
    }
}
