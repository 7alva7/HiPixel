//
//  URL+Extensions.swift
//  HiPixel
//
//  Created by 十里 on 2025/3/11.
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
        return self.deletingLastPathComponent().appendingPathComponent(newFilename).appendingPathExtension(
            pathExtension)
    }

    var imageContents: [URL] {
        guard hasDirectoryPath else { return [] }

        let fileManager = FileManager.default
        var urls = [URL]()

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: self,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )

            for childURL in contents {
                if childURL.hasDirectoryPath {
                    urls.append(contentsOf: childURL.imageContents)
                } else if childURL.isImageFile {
                    urls.append(childURL)
                }
            }
        } catch {
            Common.logger.error(("Failed to retrieve directory contents: \(error)"))
        }
        return urls
    }

    var exists: Bool {
        // var count = 0
        // if !FileManager.default.fileExists(atPath: self.path) {
        //     do {
        //         try FileManager.default.startDownloadingUbiquitousItem(at: self)
        //     } catch {
        //         Common.logger.error("sycn \(self.path) failed: \(error)")
        //     }
        // } else {
        //     return true
        // }
        // while !FileManager.default.fileExists(atPath: self.path) {
        //     count += 1
        //     if count > 10 {
        //         break
        //     }
        //     Thread.sleep(forTimeInterval: 1)
        // }

        return FileManager.default.fileExists(atPath: self.path)
    }
}
