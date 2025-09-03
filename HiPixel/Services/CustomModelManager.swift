//
//  CustomModelManager.swift
//  HiPixel
//
//  Created by okooo5km(十里) on 2025/01/03.
//

import Foundation
import SwiftUI

class CustomModelManager: ObservableObject {
    static let shared = CustomModelManager()
    
    @Published var customModels: [CustomModel] = []
    
    private init() {
        loadCustomModels()
    }
    
    struct CustomModel: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let path: String
        let displayName: String
        
        init(name: String, path: String) {
            self.name = name
            self.path = path
            self.displayName = name.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    func loadCustomModels() {
        guard let folderPath = HiPixelConfiguration.shared.customModelsFolder else {
            customModels = []
            return
        }
        
        scanForCustomModels(in: folderPath)
    }
    
    func scanForCustomModels(in folderPath: String) {
        let url = URL(fileURLWithPath: folderPath)
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            let binFiles = files.filter { $0.pathExtension.lowercased() == "bin" }
            
            var foundModels: [CustomModel] = []
            
            for binFile in binFiles {
                let modelName = binFile.deletingPathExtension().lastPathComponent
                let paramFile = url.appendingPathComponent("\(modelName).param")
                
                if fileManager.fileExists(atPath: paramFile.path) {
                    let customModel = CustomModel(name: modelName, path: url.path)
                    foundModels.append(customModel)
                }
            }
            
            customModels = foundModels.sorted { $0.name < $1.name }
        } catch {
            print("Error scanning custom models directory: \(error)")
            customModels = []
        }
    }
    
    func getModelPath(for modelName: String) -> String? {
        return customModels.first { $0.name == modelName }?.path
    }
    
    func isCustomModel(_ modelName: String) -> Bool {
        return customModels.contains { $0.name == modelName }
    }
    
    func getAllModelNames() -> [String] {
        return customModels.map { $0.name }
    }
}