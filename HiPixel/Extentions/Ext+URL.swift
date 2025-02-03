//
//  Ext+URL.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/31.
//

import SwiftUI
import UniformTypeIdentifiers

extension URL {
    var fileSize: Int {
        if !isFileURL { return 0 }
        do {
            return try FileManager.default.attributesOfItem(atPath: path)[.size] as! Int
        } catch {
            return 0
        }
    }
    
    var isImageFile: Bool {
        isFile(ofTypes: [.png, .jpeg, .webP])
    }
    
    var uti: UTType? {
        hasDirectoryPath ? nil : UTType(filenameExtension: pathExtension)
    }
    
    func isFile(ofTypes types: [UTType]) -> Bool {
        guard let uti = self.uti else {
            return false
        }
        
        return types.contains(where: { uti.conforms(to: $0) })
    }
    
    var imageRepType: NSBitmapImageRep.FileType? {
        if !isImageFile {
            return nil
        }
        switch uti {
        case UTType.png, UTType.webP:
            return .png
        case UTType.jpeg, UTType.heic:
            return .jpeg
        default:
            return nil
        }
    }
    
    var imageIdentifier: String? {
        if !isImageFile {
            return nil
        }
        switch uti {
        case UTType.png:
            return "png"
        case UTType.jpeg:
            return "jpeg"
        case UTType.webP:
            return "webp"
        default:
            return self.lastPathComponent.components(separatedBy: ".").last
        }
    }
    
    func changingPathExtension(to newExtension: String) -> URL {
        return self.deletingPathExtension().appendingPathExtension(newExtension)
    }
    
    func appendingPostfix(_ postfix: String) -> URL {
        let filename = self.deletingPathExtension().lastPathComponent
        let newFilename = "\(filename)\(postfix)"
        return self.deletingLastPathComponent().appendingPathComponent(newFilename).appendingPathExtension(pathExtension)
    }
}
