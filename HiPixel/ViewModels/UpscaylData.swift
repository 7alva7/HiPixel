//
//  UpscaylData.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/31.
//

import SwiftUI

struct UpscaylDataItem: Identifiable {
    var id: UUID
    var startAt: Date
    var url: URL
    var thumbnail: URL?
    
    var newURL: URL {
        didSet {
            newFileSize = newURL.fileSize
        }
    }
    
    var fileName: String = ""
    var size: CGSize = CGSize()
    var newSize: CGSize = CGSize()
    var fileSize: Int = 0
    var newFileSize: Int = 0
    var timeInterval: TimeInterval = 0
    var state: ProcessState
    var progress: Double = 0
    
    init(_ url: URL) {
        self.url = url
        newSize = size
        fileSize = url.fileSize
        startAt = Date.now
        state = .processing
        newURL = url
        fileName = url.lastPathComponent
        id = UUID()
    }
}

class UpscaylData: ObservableObject {
    
    static let shared = UpscaylData()
    
    @Published
    var items: [UpscaylDataItem] = []
    
    @Published
    var selectedItem: UpscaylDataItem? = nil
    
    func append(_ item: UpscaylDataItem) {
        remove(item)
        items.append(item)
        items.sort(by: { $0.startAt > $1.startAt})
    }
    
    func update(_ item: UpscaylDataItem) {
        if let index = items.firstIndex(where: { $0.url == item.url }) {
            items[index] = item
        }
    }
    
    func remove(_ item: UpscaylDataItem) {
        if items.contains(where: { $0.url == item.url }) {
            items.removeAll(where: { $0.url == item.url })
        }
    }
    
    func removeAll() {
        items.removeAll()
        Self.removeThumbnails()
    }
    
    static func removeThumbnails() {
        let thumbnailDir = Common.directory.appendingPathComponent("thumbnails")
        do {
            try FileManager.default.removeItem(at: thumbnailDir)
        } catch {
            Common.logger.error("Remove thumbnails(\(thumbnailDir.path)) failed, \(error)")
        }
    }
}

enum ProcessState: String, CaseIterable {
    case processing = "Processing"
    case success = "Done"
    case failed = "Error"
    
    var localized: String {
        return NSLocalizedString(rawValue, comment: "")
    }
}
