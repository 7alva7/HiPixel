//
//  RotatingProcessingView.swift
//  HiPixel
//
//  Created by 十里 on 2024/11/4.
//

import SwiftUI

struct RotatingProcessingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Image(systemName: "rectangle.pattern.checkered")
            .rotationEffect(.degrees(rotationAngle))
            .animation(.linear(duration: 1).delay(1).repeatForever(autoreverses: false), value: rotationAngle)
            .onAppear {
                rotationAngle += 180
            }
    }
}

struct BreathingProcessingView: View {
    @State private var isBreathing = false
    
    var body: some View {
        Image(systemName: "livephoto")
            .resizable()
            .frame(width: 32, height: 32)
            .scaleEffect(isBreathing ? 0.9 : 1.2)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isBreathing)
            .onAppear {
                isBreathing.toggle()
            }
    }
}
