//
//  SettingItem.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/22.
//

import SwiftUI

struct SettingItem: View {
    
    var title: LocalizedStringKey
    var description: LocalizedStringKey?
    var icon: String
    var trailingView: AnyView
    var bodyView: AnyView
    
    @State private var isPresented: Bool = false
    @State private var bodyHeight: CGFloat = 0
    @State private var isHovered: Bool = false
    
    private var cornerRadius: CGFloat {
        if #available(macOS 26.0, *) {
            return 12
        } else {
            return 8
        }
    }
    
    init(
        title: LocalizedStringKey,
        icon: String,
        description: LocalizedStringKey? = nil,
        trailingView: AnyView,
        bodyView: AnyView
    ) {
        self.title = title
        self.icon = icon
        self.description = description
        self.trailingView = trailingView
        self.bodyView = bodyView
    }
    
    init(
        title: LocalizedStringKey,
        icon: String,
        description: LocalizedStringKey? = nil,
        trailingView: some View = EmptyView(),
        bodyView: some View = EmptyView()
    ) {
        self.init(
            title: title,
            icon: icon,
            description: description,
            trailingView: AnyView(trailingView),
            bodyView: AnyView(bodyView)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: bodyHeight == 0 ? 0 : 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.caption)
                    .fontWeight(.bold)
                
                if let description = description {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(isHovered ? .primary : .secondary)
                        .popover(isPresented: $isPresented, content: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label(title, systemImage: icon)
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                Text(description)
                                    .multilineTextAlignment(.leading)
                                    .opacity(0.6)
                                    .lineSpacing(4)
                            }
                            .font(.caption)
                            .frame(width: 240)
                            .padding(12)
                        })
                        .onHover { hovering in
                            withAnimation {
                                isHovered = hovering
                            }
                        }
                        .onTapGesture {
                            withAnimation {
                                isPresented.toggle()
                            }
                        }
                }
                
                Spacer()
                trailingView
            }
            
            bodyView
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                bodyHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size.height) { newHeight in
                                bodyHeight = newHeight
                            }
                    }
                }
        }
        .padding(8)
        .background(cornerRadius: cornerRadius, strokeColor: .primary.opacity(0.06), fill: .background.opacity(0.6))
    }
}

#Preview {
    SettingItem(
        title: "Notification",
        icon: "wand.and.stars",
        description: "",
        trailingView: EmptyView(),
        bodyView: Group {
            Picker("", selection: .constant(HiPixelConfiguration.ColorScheme.light)) {
                ForEach(HiPixelConfiguration.ColorScheme.allCases, id: \.self) {
                    Text($0.localized)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
    )
    .padding()
    .frame(width: 320)
}
