import Foundation
import AppKit

class URLSchemeHandler {
    static let shared = URLSchemeHandler()
    private init() {}
    
    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "hipixel" else { return }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        
        let paths = components.queryItems?
            .filter { $0.name == "path" }
            .compactMap { $0.value }
            .map { $0.removingPercentEncoding ?? $0 } ?? []
        
        guard !paths.isEmpty else { return }
        
        let urls = paths.compactMap { path -> URL? in
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: path) else {
                return nil
            }
            guard url.isImageFile || url.isFile(ofTypes: [.folder]) else {
                return nil
            }
            return url
        }
        
        guard !urls.isEmpty else { return }
        
        DispatchQueue.main.async {
            Upscayl.process(urls, by: UpscaylData.shared)
        }
    }
}
