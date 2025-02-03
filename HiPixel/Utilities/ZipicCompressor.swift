import Foundation
import AppKit

enum ZipicCompressor {
    static func compress(url: URL, saveDirectory: URL?, format: String? = nil, level: Double = 3.0) {
        var components = URLComponents(string: "zipic://compress")
        var queryItems = [URLQueryItem]()
        
        // Add source URL
        queryItems.append(URLQueryItem(name: "url", value: url.path))
        
        // Add compression level
        queryItems.append(URLQueryItem(name: "level", value: "\(level)"))
        
        // Add format if specified
        if let format = format {
            queryItems.append(URLQueryItem(name: "format", value: format))
        }
        
        // Add save directory if specified
        if let saveDirectory = saveDirectory {
            queryItems.append(URLQueryItem(name: "location", value: "custom"))
            queryItems.append(URLQueryItem(name: "directory", value: saveDirectory.path))
        }
        
        components?.queryItems = queryItems
        
        guard let zipicURL = components?.url else { return }
        NSWorkspace.shared.open(zipicURL)
    }
    
    static func compressMultiple(urls: [URL], saveDirectory: URL?, format: String? = nil, level: Double = 3.0) {
        var components = URLComponents(string: "zipic://compress")
        var queryItems = [URLQueryItem]()
        
        // Add all source URLs
        for url in urls {
            queryItems.append(URLQueryItem(name: "url", value: url.path))
        }
        
        // Add compression level
        queryItems.append(URLQueryItem(name: "level", value: "\(level)"))
        
        // Add format if specified
        if let format = format {
            queryItems.append(URLQueryItem(name: "format", value: format))
        }
        
        // Add save directory if specified
        if let saveDirectory = saveDirectory {
            queryItems.append(URLQueryItem(name: "location", value: "custom"))
            queryItems.append(URLQueryItem(name: "directory", value: saveDirectory.path))
        }
        
        components?.queryItems = queryItems
        
        guard let zipicURL = components?.url else { return }
        NSWorkspace.shared.open(zipicURL)
    }
}
