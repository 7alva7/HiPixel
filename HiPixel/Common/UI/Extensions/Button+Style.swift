//
//  Ext+Button.swift
//  HiPixel
//
//  Created by 十里 on 2025/1/18.
//

import SwiftUI

// 1. Define configuration struct
struct GradientButtonConfiguration {
    // Basic style
    var cornerRadius: CGFloat = 12
    var horizontalPadding: CGFloat = 12
    var verticalPadding: CGFloat = 8

    // Color configuration
    var startColor: Color = Color(hex: "#55AAEF")!
    var endColor: Color = .blue
    var foregroundColor: Color = .white

    // Gradient direction
    var gradientStartPoint: UnitPoint = .top
    var gradientEndPoint: UnitPoint = .bottom

    // Border configuration
    var borderWidth: CGFloat = 1
    var borderStartColor: Color = .white.opacity(0.4)
    var borderEndColor: Color = .clear

    // Interaction effects
    var pressedScale: CGFloat = 0.95
    var pressedOpacity: Double = 0.8
    var animation: Animation = .easeInOut(duration: 0.2)

    // Shadow configuration
    var shadowColor: Color = .clear
    var shadowRadius: CGFloat = 0
    var shadowX: CGFloat = 0
    var shadowY: CGFloat = 0

    // Disabled state configuration
    var disabledOpacity: Double = 0.6

    static let `default` = GradientButtonConfiguration()
}

// 2. Define button style
struct GradientButtonStyle: ButtonStyle {
    let configuration: GradientButtonConfiguration
    @Environment(\.isEnabled) private var isEnabled

    init(configuration: GradientButtonConfiguration = .default) {
        self.configuration = configuration
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(self.configuration.foregroundColor)
            .padding(.horizontal, self.configuration.horizontalPadding)
            .padding(.vertical, self.configuration.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: self.configuration.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                self.configuration.startColor,
                                self.configuration.endColor,
                            ],
                            startPoint: self.configuration.gradientStartPoint,
                            endPoint: self.configuration.gradientEndPoint
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: self.configuration.cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                self.configuration.borderStartColor,
                                self.configuration.borderEndColor,
                            ],
                            startPoint: self.configuration.gradientStartPoint,
                            endPoint: self.configuration.gradientEndPoint
                        ),
                        lineWidth: self.configuration.borderWidth
                    )
            )
            .shadow(
                color: self.configuration.shadowColor,
                radius: self.configuration.shadowRadius,
                x: self.configuration.shadowX,
                y: self.configuration.shadowY
            )
            .scaleEffect(configuration.isPressed ? self.configuration.pressedScale : 1.0)
            .opacity(configuration.isPressed ? self.configuration.pressedOpacity : 1.0)
            .opacity(isEnabled ? 1.0 : self.configuration.disabledOpacity)
            .animation(self.configuration.animation, value: configuration.isPressed)
    }
}

// 3. Add convenience extension
extension ButtonStyle where Self == GradientButtonStyle {
    static var gradient: GradientButtonStyle { .init() }

    static func gradient(
        configuration: GradientButtonConfiguration = .default
    ) -> GradientButtonStyle {
        .init(configuration: configuration)
    }
}

// 4. Preset styles
extension GradientButtonConfiguration {
    static let primary = GradientButtonConfiguration(
        startColor: Color(hex: "#55AAEF")!,
        endColor: .blue
    )

    static let secondary = GradientButtonConfiguration(
        startColor: Color.secondary.opacity(0.8),
        endColor: Color.secondary
    )

    static let success = GradientButtonConfiguration(
        startColor: .green.opacity(0.8),
        endColor: .green
    )

    static let danger = GradientButtonConfiguration(
        startColor: .pink.opacity(0.8),
        endColor: .pink
    )

    static let fancy = GradientButtonConfiguration(
        cornerRadius: 20,
        horizontalPadding: 20,
        verticalPadding: 12,
        startColor: .purple,
        endColor: .pink,
        shadowRadius: 8,
        shadowY: 4
    )
}
