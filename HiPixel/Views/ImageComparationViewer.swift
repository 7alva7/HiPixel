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
    private var sliderPosition: CGFloat = 0.5  // 拖动条的初始位置

    @State
    private var hoveringOnSlider = false

    @State
    private var magnification: CGFloat = 1.0  // 缩放比例

    @State
    private var offset: CGSize = .zero  // 拖动偏移

    @State
    private var lastMagnification: CGFloat = 1.0

    @State
    private var lastOffset: CGSize = .zero

    @State
    private var isDraggingSlider = false  // 跟踪是否正在拖动 slider

    @State
    private var hoveredZoomButton: ZoomButtonType? = nil  // 跟踪悬浮的按钮

    private let minMagnification: CGFloat = 1.0
    private let maxMagnification: CGFloat = 5.0
    private let zoomStep: CGFloat = 0.25  // 每次缩放步长

    var body: some View {
        GeometryReader { geometry in
            let imageSize = NSImage(contentsOf: leftImage)?.size ?? geometry.size
            let imageWidth = imageSize.width * geometry.size.height / imageSize.height

            // 计算缩放后的图像尺寸和拖动限制
            let scaledWidth = geometry.size.width * magnification
            let scaledHeight = geometry.size.height * magnification
            let maxOffsetX = max(0, (scaledWidth - geometry.size.width) / 2)
            let maxOffsetY = max(0, (scaledHeight - geometry.size.height) / 2)

            // 计算 slider 的拖动范围（考虑缩放）
            let scaledImageWidth = imageWidth * magnification
            let scaledImageHalfWidth = scaledImageWidth / 2

            // 如果缩放后的图像宽度大于等于 view 宽度，slider 可以拖动到边缘
            // 否则根据缩放后的图像尺寸计算范围
            let minPosition =
                scaledImageWidth >= geometry.size.width
                ? 0.001
                : max(0.5 - scaledImageHalfWidth / geometry.size.width, 0.001)
            let maxPosition =
                scaledImageWidth >= geometry.size.width
                ? 0.999
                : min(0.5 + scaledImageHalfWidth / geometry.size.width, 0.999)

            ZStack(alignment: .leading) {
                AsyncImage(url: rightImage) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(magnification)
                        .offset(offset)
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
                        .scaleEffect(magnification)
                        .offset(offset)
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
                    VStack(spacing: 0) {
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
                    .shadow(radius: 1, x: 0, y: 0)

                    Circle()
                        .fill(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .shadow(radius: 1, x: 0, y: 0)

                    Circle()
                        .stroke(.white, lineWidth: 2)
                        .frame(width: 36, height: 36)
                        .shadow(radius: 1, x: 0, y: 0)

                    HStack(spacing: 4) {
                        Image(systemName: "arrowtriangle.left.fill")
                        Image(systemName: "arrowtriangle.right.fill")
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                }
                .opacity(hoveringOnSlider ? 1.0 : 0.8)
                .offset(x: sliderPosition * geometry.size.width - 18)
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            isDraggingSlider = true
                            sliderPosition = min(max(minPosition, value.location.x / geometry.size.width), maxPosition)
                        }
                        .onEnded { _ in
                            isDraggingSlider = false
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
            .overlay(alignment: .bottomLeading) {
                ZoomControlsView(
                    magnification: $magnification,
                    lastMagnification: $lastMagnification,
                    offset: $offset,
                    lastOffset: $lastOffset,
                    hoveredButton: $hoveredZoomButton,
                    minMagnification: minMagnification,
                    maxMagnification: maxMagnification,
                    zoomStep: zoomStep
                )
                .padding(8)
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newMagnification = lastMagnification * value
                        magnification = min(max(1.0, newMagnification), 5.0)  // 限制缩放范围 1x-5x
                    }
                    .onEnded { value in
                        lastMagnification = magnification
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        // 如果正在拖动 slider，忽略图像拖动
                        guard !isDraggingSlider else { return }

                        // 只在放大状态下允许拖动
                        guard magnification > 1.0 else { return }

                        // 检查是否在 slider 区域（避免与 slider 拖动冲突）
                        let sliderX = sliderPosition * geometry.size.width
                        let sliderRect = CGRect(
                            x: sliderX - 30,
                            y: 0,
                            width: 60,
                            height: geometry.size.height
                        )
                        if sliderRect.contains(value.startLocation) {
                            return
                        }

                        let newOffsetX = lastOffset.width + value.translation.width
                        let newOffsetY = lastOffset.height + value.translation.height

                        // 限制拖动范围
                        offset = CGSize(
                            width: min(max(-maxOffsetX, newOffsetX), maxOffsetX),
                            height: min(max(-maxOffsetY, newOffsetY), maxOffsetY)
                        )
                    }
                    .onEnded { _ in
                        if !isDraggingSlider {
                            lastOffset = offset
                        }
                    }
            )
            .onTapGesture(count: 2) {
                // 双击重置缩放和位置
                resetZoom()
            }
        }
        .clipped()
    }

    private func resetZoom() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            magnification = 1.0
            offset = .zero
            lastMagnification = 1.0
            lastOffset = .zero
        }
    }
}

// MARK: - Zoom Controls

enum ZoomButtonType {
    case zoomIn
    case zoomOut
}

struct ZoomControlsView: View {
    @Binding var magnification: CGFloat
    @Binding var lastMagnification: CGFloat
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    @Binding var hoveredButton: ZoomButtonType?

    let minMagnification: CGFloat
    let maxMagnification: CGFloat
    let zoomStep: CGFloat

    private let zoomLevels: [CGFloat] = [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0]

    var body: some View {
        HStack(spacing: 8) {
            // 缩小按钮
            ZoomButton(
                icon: "minus.magnifyingglass",
                isEnabled: magnification > minMagnification,
                isHovered: hoveredButton == .zoomOut
            ) {
                hoveredButton = .zoomOut
            } onExit: {
                hoveredButton = nil
            } action: {
                let newMagnification = max(magnification - zoomStep, minMagnification)
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    magnification = newMagnification
                    lastMagnification = newMagnification
                    if newMagnification == 1.0 {
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }

            // 百分比显示和选择器
            Menu {
                ForEach(zoomLevels, id: \.self) { level in
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            magnification = level
                            lastMagnification = level
                            if level == 1.0 {
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    } label: {
                        HStack {
                            Text("\(Int(level * 100))%")
                            if magnification == level {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text("\(Int(magnification * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .fontDesign(.monospaced)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.background.opacity(0.7))
                    )
                    .foregroundStyle(.primary)
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)

            // 放大按钮
            ZoomButton(
                icon: "plus.magnifyingglass",
                isEnabled: magnification < maxMagnification,
                isHovered: hoveredButton == .zoomIn
            ) {
                hoveredButton = .zoomIn
            } onExit: {
                hoveredButton = nil
            } action: {
                let newMagnification = min(magnification + zoomStep, maxMagnification)
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    magnification = newMagnification
                    lastMagnification = newMagnification
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.background.opacity(0.8))
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 0.4)
        )
    }
}

struct ZoomButton: View {
    let icon: String
    let isEnabled: Bool
    let isHovered: Bool
    let onHover: () -> Void
    let onExit: () -> Void
    let action: () -> Void

    init(
        icon: String,
        isEnabled: Bool,
        isHovered: Bool,
        onHover: @escaping () -> Void,
        onExit: @escaping () -> Void,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.isEnabled = isEnabled
        self.isHovered = isHovered
        self.onHover = onHover
        self.onExit = onExit
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.background.opacity(isHovered ? 0.9 : 0.6))
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .foregroundStyle(isEnabled ? .primary : Color.secondary.opacity(0.5))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in
            if hovering {
                onHover()
            } else {
                onExit()
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                // Animation handled by isHovered binding
            }
        }
    }
}
