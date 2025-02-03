//
//  ImageComparationViewer.swift
//  HiPixel
//
//  Created by 十里 on 2024/11/3.
//

import SwiftUI

struct ImageComparationViewer: View {
    
    var leftImage: URL
    var rightImage: URL
    
    @State
    private var sliderPosition: CGFloat = 0.5 // 拖动条的初始位置
    
    @State
    private var hoveringOnSlider = false
    
    var body: some View {
        GeometryReader { geometry in
            let imageSize = NSImage(contentsOf: leftImage)?.size ?? geometry.size
            let imageWidth = imageSize.width * geometry.size.height / imageSize.height
            let imageHalfWidth = imageWidth / 2
            let minPosition =  imageWidth < geometry.size.width ? max(0.5 - imageHalfWidth / geometry.size.width, 0.001) : 0.001
            let maxPosition = imageWidth < geometry.size.width ? min(0.5 + imageHalfWidth / geometry.size.width, 0.999) : 0.999
            
            ZStack(alignment: .leading) {
                AsyncImage(url: rightImage) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } placeholder: {
                    Color.gray
                }
                .mask(
                    HStack {
                        Spacer()
                        Rectangle()
                            .frame(width: (1 - sliderPosition) * geometry.size.width)
                    }
                )
                
                AsyncImage(url: leftImage) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } placeholder: {
                    Color.gray
                }
                .mask(
                    HStack {
                        Rectangle()
                            .frame(width: sliderPosition * geometry.size.width)
                        Spacer()
                    }
                )
                
                ZStack {
                    VStack(spacing:0) {
                        Rectangle()
                            .frame(width: 2)
                            .foregroundStyle(.clear)
                            .background(.white.opacity(0.9))
                        
                        Rectangle()
                            .frame(width: 2, height: 36)
                            .foregroundStyle(.clear)
                            .background(.clear)
                        
                        Rectangle()
                            .frame(width: 2)
                            .foregroundStyle(.clear)
                            .background(.white.opacity(0.9))
                    }
                    .shadow(radius: 1, x:0, y:0)
                    
                    Circle()
                        .fill(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .shadow(radius: 1, x:0, y:0)
                    
                    Circle()
                        .stroke(.white, lineWidth: 2)
                        .frame(width: 36, height: 36)
                        .shadow(radius: 1, x:0, y:0)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrowtriangle.left.fill")
                        Image(systemName: "arrowtriangle.right.fill")
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                }
                .opacity(hoveringOnSlider ? 1.0 : 0.8)
                .offset(x: sliderPosition * geometry.size.width - 18)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            sliderPosition = min(max(minPosition, value.location.x / geometry.size.width), maxPosition)
                        }
                )
                .onHover { hovering in
                    if hovering {
                        NSCursor.resizeLeftRight.set()
                        hoveringOnSlider = true
                    } else {
                        NSCursor.arrow.set()
                        hoveringOnSlider = false
                    }
                }
            }
            .cornerRadius(6)
        }
        .clipped()
    }
}

