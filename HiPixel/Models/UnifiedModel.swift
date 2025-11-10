//
//  UnifiedModel.swift
//  HiPixel
//
//  Created by 十里 on 2025/01/03.
//

import Foundation
import SwiftUI

protocol ModelProtocol {
    var id: String { get }
    var displayName: String { get }
    var isBuiltIn: Bool { get }
    var modelPath: String? { get }
}

enum UnifiedModel: Hashable, Identifiable, ModelProtocol {
    case builtIn(HiPixelConfiguration.UpscaylModel)
    case custom(CustomModelManager.CustomModel)
    
    var id: String {
        switch self {
        case .builtIn(let model):
            return "builtin_\(model.id)"
        case .custom(let model):
            return "custom_\(model.name)"
        }
    }
    
    var displayName: String {
        switch self {
        case .builtIn(let model):
            return model.text
        case .custom(let model):
            return model.displayName
        }
    }
    
    var isBuiltIn: Bool {
        switch self {
        case .builtIn(_):
            return true
        case .custom(_):
            return false
        }
    }
    
    var modelPath: String? {
        switch self {
        case .builtIn(_):
            return nil // Built-in models use default path
        case .custom(let model):
            return model.path
        }
    }
    
    var modelName: String {
        switch self {
        case .builtIn(let model):
            return model.id
        case .custom(let model):
            return model.name
        }
    }
    
    // Convert back to original types when needed
    var upscaylModel: HiPixelConfiguration.UpscaylModel? {
        switch self {
        case .builtIn(let model):
            return model
        case .custom(_):
            return nil
        }
    }
    
    var customModel: CustomModelManager.CustomModel? {
        switch self {
        case .builtIn(_):
            return nil
        case .custom(let model):
            return model
        }
    }
    
    // Static methods to create unified model lists
    static func getAllModels() -> [UnifiedModel] {
        var models: [UnifiedModel] = []
        
        // Add built-in models
        for builtInModel in HiPixelConfiguration.UpscaylModel.allCases {
            models.append(.builtIn(builtInModel))
        }
        
        // Add custom models
        for customModel in CustomModelManager.shared.customModels {
            models.append(.custom(customModel))
        }
        
        return models
    }
    
    static func fromStoredValue(_ storedModel: HiPixelConfiguration.UpscaylModel, customModelName: String?) -> UnifiedModel {
        // If there's a custom model name, try to find it
        if let customName = customModelName,
           let customModel = CustomModelManager.shared.customModels.first(where: { $0.name == customName }) {
            return .custom(customModel)
        }
        
        // Otherwise return the built-in model
        return .builtIn(storedModel)
    }
}

// Extension to help with storage
extension UnifiedModel {
    var storageData: (builtInModel: HiPixelConfiguration.UpscaylModel, customModelName: String?) {
        switch self {
        case .builtIn(let model):
            return (model, nil)
        case .custom(let model):
            // Use a default built-in model as fallback
            return (HiPixelConfiguration.UpscaylModel.Upscayl_Standard, model.name)
        }
    }
}