//
//  Ext+Color.swift
//  HiPixel
//
//  Created by 十里 on 2025/1/29.
//

import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
            
        } else if length == 3 {
            r = CGFloat((rgb & 0xF00) >> 8) / 15.0
            g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            b = CGFloat(rgb & 0x00F) / 15.0
            
        } else if length == 4 {
            r = CGFloat((rgb & 0xF000) >> 12) / 15.0
            g = CGFloat((rgb & 0x0F00) >> 8) / 15.0
            b = CGFloat((rgb & 0x00F0) >> 4) / 15.0
            a = CGFloat(rgb & 0x000F) / 15.0
            
        } else {
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

extension LinearGradient {
    
    static let lblue = LinearGradient(colors: [Color(hex: "#307FE1")!, Color(hex: "#03367E")!], startPoint: .top, endPoint: .bottom)
    
    static let dblue = LinearGradient(colors: [Color(hex: "#A9DDFF")!, Color(hex: "#348ACC")!], startPoint: .top, endPoint: .bottom)
    
    static let lgreen = LinearGradient(colors: [Color(hex: "#9FE130")!, Color(hex: "#3A7E03")!], startPoint: .top, endPoint: .bottom)
    
    static let dgreen = LinearGradient(colors: [Color(hex: "#B1DF88")!, Color(hex: "#8FCC34")!], startPoint: .top, endPoint: .bottom)
    
}

