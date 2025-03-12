//
//  Color+LinearGradient.swift
//  HiPixel
//
//  Created by 十里 on 2025/3/11.
//

import SwiftUI

extension LinearGradient {

    static let lblue = LinearGradient(
        colors: [Color(hex: "#307FE1")!, Color(hex: "#03367E")!], startPoint: .top, endPoint: .bottom)

    static let dblue = LinearGradient(
        colors: [Color(hex: "#A9DDFF")!, Color(hex: "#348ACC")!], startPoint: .top, endPoint: .bottom)

    static let lgreen = LinearGradient(
        colors: [Color(hex: "#9FE130")!, Color(hex: "#3A7E03")!], startPoint: .top, endPoint: .bottom)

    static let dgreen = LinearGradient(
        colors: [Color(hex: "#B1DF88")!, Color(hex: "#8FCC34")!], startPoint: .top, endPoint: .bottom)

}
