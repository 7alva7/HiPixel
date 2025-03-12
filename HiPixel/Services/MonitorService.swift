//
//  MonitorService.swift
//  HiPixel
//
//  Created by 十里 on 2025/03/11.
//

import SwiftUI

class MonitorService: ObservableObject {
    static let shared = MonitorService()

    static let monitorItemsKey = "monitorItems"

    @Published var items: [MonitorItem] = []

    private var timer: Timer?

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
                    startMonitor()
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
        stopMonitor()
        items.append(item)
        whiteList[item.url] = Set(item.url.imageContents)
        save()
        startMonitor()
    }

    func remove(_ item: MonitorItem) {
        stopMonitor()
        whiteList.removeValue(forKey: item.url)
        items.removeAll(where: { $0.id == item.id })
        save()
        if !items.isEmpty {
            startMonitor()
        }
    }

    func removeAll() {
        items.removeAll()
        save()
    }

    func update(_ item: MonitorItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let origin = items[index]
            stopMonitor()
            items[index] = item
            whiteList.removeValue(forKey: origin.url)
            whiteList[item.url] = Set(item.url.imageContents)
            save()
            startMonitor()
        }
    }

    func contains(_ item: MonitorItem) -> Bool {
        return items.contains(where: { $0.url == item.url })
    }

    func startMonitor() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if self?.items.isEmpty == true {
                self?.stopMonitor()
                return
            }
            let items = (self?.items ?? []).filter {
                $0.enabled
            }
            for item in items {
                let images = item.url.imageContents
                let whiteList = self?.whiteList[item.url] ?? []
                let targetImages = images.filter { !whiteList.contains($0) }
                if targetImages.isEmpty {
                    if UpscaylData.shared.items.filter({ $0.state == .processing }).isEmpty {
                        self?.whiteList[item.url] = Set(images)
                    }
                    continue
                }
                self?.whiteList[item.url]?.formUnion(targetImages)
                let compressedImages = targetImages.map {
                    return Self.makeOutputURL(for: $0)
                }
                self?.whiteList[item.url]?.formUnion(Set(compressedImages))
                Upscayl.process(targetImages, by: UpscaylData.shared)
            }
        }
    }

    func stopMonitor() {
        timer?.invalidate()
        timer = nil
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
