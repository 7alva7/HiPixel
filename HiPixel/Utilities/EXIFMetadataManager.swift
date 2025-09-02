//
//  EXIFMetadataManager.swift
//  HiPixel
//
//  Created by okooo5km(十里) on 2025/09/02.
//

import Foundation
import ImageIO
import CoreGraphics

class EXIFMetadataManager {
    
    // MARK: - Public Methods
    
    /// Extract metadata from image file
    /// - Parameter url: Image file URL
    /// - Returns: Metadata dictionary or nil if extraction failed
    static func extractMetadata(from url: URL) -> CFDictionary? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            Common.logger.error("Failed to create image source for: \(url.path)")
            return nil
        }
        
        let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
        return metadata
    }
    
    /// Apply metadata to an image file
    /// - Parameters:
    ///   - metadata: Metadata dictionary to apply
    ///   - url: Target image file URL
    /// - Returns: Success status
    @discardableResult
    static func applyMetadata(_ metadata: CFDictionary, to url: URL) -> Bool {
        // Read the original image data
        guard let imageData = try? Data(contentsOf: url) else {
            Common.logger.error("Failed to read image data from: \(url.path)")
            return false
        }
        
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            Common.logger.error("Failed to create image source from data")
            return false
        }
        
        // Get the UTI type for the image
        guard let imageUTI = CGImageSourceGetType(imageSource) else {
            Common.logger.error("Failed to get image UTI type")
            return false
        }
        
        // Create destination with the same format
        let destinationData = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(
            destinationData, imageUTI, 1, nil
        ) else {
            Common.logger.error("Failed to create image destination")
            return false
        }
        
        // Get the image
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            Common.logger.error("Failed to create CGImage from source")
            return false
        }
        
        // Filter metadata based on format compatibility
        let filteredMetadata = filterMetadataForFormat(metadata, format: imageUTI)
        
        // Add image with metadata to destination
        CGImageDestinationAddImage(imageDestination, cgImage, filteredMetadata)
        
        // Finalize the destination
        guard CGImageDestinationFinalize(imageDestination) else {
            Common.logger.error("Failed to finalize image destination")
            return false
        }
        
        // Write the data back to file
        do {
            try destinationData.write(to: url, options: .atomic)
            Common.logger.info("Successfully applied metadata to: \(url.lastPathComponent)")
            return true
        } catch {
            Common.logger.error("Failed to write image with metadata: \(error)")
            return false
        }
    }
    
    /// Compare and copy metadata from source to destination if different
    /// - Parameters:
    ///   - sourceURL: Source image URL
    ///   - destinationURL: Destination image URL
    /// - Returns: Success status
    @discardableResult
    static func compareAndCopyMetadata(from sourceURL: URL, to destinationURL: URL) -> Bool {
        guard let sourceMetadata = extractMetadata(from: sourceURL) else {
            Common.logger.warning("No metadata found in source image: \(sourceURL.lastPathComponent)")
            return false
        }
        
        let destinationMetadata = extractMetadata(from: destinationURL)
        
        // If destination has no metadata or metadata is different, apply source metadata
        if destinationMetadata == nil || !metadataIsEqual(sourceMetadata, destinationMetadata!) {
            Common.logger.info("Applying metadata from \(sourceURL.lastPathComponent) to \(destinationURL.lastPathComponent)")
            return applyMetadata(sourceMetadata, to: destinationURL)
        } else {
            Common.logger.info("Metadata already matches, skipping: \(destinationURL.lastPathComponent)")
            return true
        }
    }
    
    // MARK: - Private Methods
    
    /// Filter metadata based on format compatibility
    /// - Parameters:
    ///   - metadata: Original metadata dictionary
    ///   - format: Target image format UTI
    /// - Returns: Filtered metadata dictionary
    private static func filterMetadataForFormat(_ metadata: CFDictionary, format: CFString) -> CFDictionary {
        let mutableMetadata = NSMutableDictionary(dictionary: metadata)
        let formatString = format as String
        
        // For PNG format, remove EXIF-specific properties that are not supported
        if formatString.contains("png") {
            // PNG supports limited metadata, keep only basic properties
            let supportedKeys = [
                kCGImagePropertyOrientation,
                kCGImagePropertyColorModel,
                kCGImagePropertyPixelWidth,
                kCGImagePropertyPixelHeight,
                kCGImagePropertyDPIWidth,
                kCGImagePropertyDPIHeight
            ]
            
            let filteredDict = NSMutableDictionary()
            for key in supportedKeys {
                if let value = mutableMetadata[key] {
                    filteredDict[key] = value
                }
            }
            
            // Add PNG-specific metadata if available
            if let pngDict = mutableMetadata[kCGImagePropertyPNGDictionary] {
                filteredDict[kCGImagePropertyPNGDictionary] = pngDict
            }
            
            return filteredDict
        }
        
        // For WEBP format, keep basic metadata
        if formatString.contains("webp") {
            let supportedKeys = [
                kCGImagePropertyOrientation,
                kCGImagePropertyPixelWidth,
                kCGImagePropertyPixelHeight,
                kCGImagePropertyDPIWidth,
                kCGImagePropertyDPIHeight
            ]
            
            let filteredDict = NSMutableDictionary()
            for key in supportedKeys {
                if let value = mutableMetadata[key] {
                    filteredDict[key] = value
                }
            }
            
            return filteredDict
        }
        
        // For JPEG and other formats, return all metadata
        return metadata
    }
    
    /// Compare two metadata dictionaries for equality
    /// - Parameters:
    ///   - metadata1: First metadata dictionary
    ///   - metadata2: Second metadata dictionary
    /// - Returns: True if metadata is equivalent
    private static func metadataIsEqual(_ metadata1: CFDictionary, _ metadata2: CFDictionary) -> Bool {
        let dict1 = metadata1 as NSDictionary
        let dict2 = metadata2 as NSDictionary
        
        // Focus on key properties that matter most
        let importantKeys = [
            kCGImagePropertyOrientation,
            kCGImagePropertyExifDictionary,
            kCGImagePropertyGPSDictionary,
            kCGImagePropertyTIFFDictionary,
            kCGImagePropertyIPTCDictionary
        ]
        
        for key in importantKeys {
            let value1 = dict1[key]
            let value2 = dict2[key]
            
            // If both are nil, continue
            if value1 == nil && value2 == nil {
                continue
            }
            
            // If one is nil and the other is not, they're different
            if (value1 == nil) != (value2 == nil) {
                return false
            }
            
            // Compare the values
            if let val1 = value1 as? NSDictionary,
               let val2 = value2 as? NSDictionary {
                if !val1.isEqual(to: val2 as! [AnyHashable : Any]) {
                    return false
                }
            } else if let val1 = value1,
                      let val2 = value2,
                      !isEqual(val1, val2) {
                return false
            }
        }
        
        return true
    }
    
    /// Helper method to compare two values
    /// - Parameters:
    ///   - value1: First value
    ///   - value2: Second value
    /// - Returns: True if values are equal
    private static func isEqual(_ value1: Any, _ value2: Any) -> Bool {
        if let str1 = value1 as? String, let str2 = value2 as? String {
            return str1 == str2
        }
        if let num1 = value1 as? NSNumber, let num2 = value2 as? NSNumber {
            return num1 == num2
        }
        if let dict1 = value1 as? NSDictionary, let dict2 = value2 as? NSDictionary {
            return dict1.isEqual(to: dict2 as! [AnyHashable : Any])
        }
        return false
    }
}