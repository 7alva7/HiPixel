//
//  Botton+Configuration.swift
//  HiPixel
//
//  Created by 十里 on 2025/3/11.
//

import SwiftUI

extension GradientButtonConfiguration {
    static let buyMeACoffee = GradientButtonConfiguration(
        startColor: Color(hex: "#FFDD00")!,
        endColor: Color(hex: "#FFD000")!,
        foregroundColor: .black.opacity(0.8)
    )

    static let alipay = GradientButtonConfiguration(
        startColor: Color(hex: "#1677FF")!,
        endColor: Color(hex: "#0E5FD8")!
    )

    static let wechatPay = GradientButtonConfiguration(
        startColor: Color(hex: "#07C160")!,
        endColor: Color(hex: "#059B4C")!
    )
}
