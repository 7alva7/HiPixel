//
//  Ext+NSImage.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/31.
//

import SwiftUI

extension NSImage {
    
    var pixelSize: CGSize {
        if let bitmapRep = self.representations.first as? NSBitmapImageRep {
            CGSize(width: bitmapRep.pixelsWide, height: bitmapRep.pixelsHigh)
        } else {
            self.size
        }
    }
    
    func thumbnail(with width: CGFloat) -> NSImage {
        let widthOfRect = width
        let thumbnailSize = NSSize(width: widthOfRect, height: widthOfRect / self.size.width * self.size.height)
        let thumbnailRect = NSRect(x: 0, y: 0, width: widthOfRect, height: thumbnailSize.height)
        
        let thumbnailImage = NSImage(size: thumbnailSize)
        thumbnailImage.lockFocus()
        self.draw(in: thumbnailRect, from: NSRect.zero, operation: .sourceOver, fraction: 1.0)
        thumbnailImage.unlockFocus()
        return thumbnailImage
    }
    
    func saveAtThumbnailDirectory(as fileName: String) -> URL? {
        guard let imageData = self.tiffRepresentation else {
            return nil
        }
        let bitmap = NSBitmapImageRep(data: imageData)
        guard let pngData = bitmap?.representation(using: .png, properties: [:]) else {
            return nil
        }
        let thumbnailsDirectory = Common.directory.appendingPathComponent("thumbnails")
        guard let imageUrl = URL(string: fileName) else {
            return nil
        }
        
        if !FileManager.default.fileExists(atPath: thumbnailsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Common.logger.error("create the thumbnails directory failed：\(error)")
                return nil
            }
        }
        
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(imageUrl.lastPathComponent).changingPathExtension(to: "png")
        
        do{
            try pngData.write(to: thumbnailURL, options: .atomic)
        } catch {
            Common.logger.error("save \(fileName) failed!")
            return nil
        }
        
        return thumbnailURL
    }
}
