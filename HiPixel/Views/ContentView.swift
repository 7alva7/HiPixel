//
//  ContentView.swift
//  HiPixel
//
//  Created by 十里 on 2024/6/16.
//

import SwiftUI

struct ContentView: View, DropDelegate {
    
    @AppStorage(HiPixelConfiguration.Keys.ColorScheme)
    var colorScheme: HiPixelConfiguration.ColorScheme = .system
    
    @State var isGalleryPresented: Bool = false
    
    @State var isOptionsPresented: Bool = false
    
    @State var isFilePanelPresented: Bool = false
    
    @State private var dropOver = false
    
    @EnvironmentObject var upscaylData: UpscaylData
    
    var body: some View {
        VStack(spacing: 8) {
            VStack {
                if let item = upscaylData.selectedItem {
                    switch item.state {
                    case .processing:
                        GeometryReader { geometry in
                            AsyncImage(url: item.url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .blur(radius: 16)
                            } placeholder: {
                                Color.gray
                            }
                            .overlay(alignment: .center) {
                                VStack(spacing: 8) {
                                    BreathingProcessingView()
                                        .font(.title)
                                    Text("\(item.progress, specifier: "%.0f")%")
                                        .font(.title)
                                        .fontDesign(.monospaced)
                                    Text("Processing...")
                                        .font(.caption)
                                }
                                .padding(16)
                                .background(cornerRadius: 16, fill: .background.opacity(0.8))
                                .foregroundStyle(.secondary)
                                .fontWeight(.bold)
                            }
                        }
                    case .failed:
                        GeometryReader { geometry in
                            AsyncImage(url: item.url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            } placeholder: {
                                Color.gray
                            }
                            .overlay(alignment: .center) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("\(item.size.width, specifier: "%.0f")×\(item.size.height, specifier: "%.0f") px", systemImage: "viewfinder.rectangular")
                                        .font(.caption)
                                    Text("Failed to process")
                                        .font(.headline)
                                }
                                .padding(16)
                                .background(cornerRadius: 16, fill: .background.opacity(0.8))
                                .foregroundStyle(.secondary)
                                .fontWeight(.bold)
                            }
                        }
                    case .success:
                        ImageComparationViewer(leftImage: item.url, rightImage: item.newURL)
                            .overlay(alignment: .top) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Original Image")
                                            .font(.headline)
                                        Label("\(item.size.width, specifier: "%.0f")×\(item.size.height, specifier: "%.0f") px", systemImage: "viewfinder.rectangular")
                                            .font(.caption)
                                    }
                                    .padding(16)
                                    .background(cornerRadius: 16, fill: .background.opacity(0.8))
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 8) {
                                        Text("HiPixeled Image")
                                            .font(.headline)
                                        Label("\(item.newSize.width, specifier: "%.0f")×\(item.newSize.height, specifier: "%.0f") px", systemImage: "viewfinder.rectangular")
                                            .font(.caption)
                                    }
                                    .padding(16)
                                    .background(cornerRadius: 16, fill: .background.opacity(0.8))
                                }
                                .foregroundStyle(.secondary)
                                .fontWeight(.bold)
                                .padding(8)
                            }
                    }
                } else {
                    AppInfoView()
                    
                    Text("✨ Drag image files or folders here ✨")
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .font(.system(size: 15, weight: .heavy))
                    
                    VStack(spacing: 5) {
                        Text("Supported Image Formats")
                            .font(.system(size: 10, weight: .light))
                        Text("**PNG** • **JPEG** • **WebP**")
                            .font(.system(size: 10))
                        
                    }
                    .frame(width: 180)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .background(
                cornerRadius: 8,
                strokeColor: .primary.opacity(upscaylData.selectedItem == nil ? 0 : 0.1),
                fill: .background.opacity(upscaylData.selectedItem == nil ? 0 : 0.4)
            )
            .padding(.init(
                top: 8,
                leading: 8,
                bottom: isGalleryPresented ? 0 : 8,
                trailing: 8
            ))
            
            if isGalleryPresented {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.spring) {
                            isFilePanelPresented.toggle()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .fontWeight(.semibold)
                            .frame(width: 64, height: 64)
                            .foregroundStyle(.white)
                            .background(
                                cornerRadius: 16,
                                fill: LinearGradient(
                                    colors: [
                                        Color(hex: "#55AAEF")!,
                                        .blue,
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.5),
                                                .clear,
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                    
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 8) {
                            ForEach(upscaylData.items, id: \.id) { item in
                                ThumbnailView(item: item)
                            }
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 80)
                    }
                }
                .frame(height: 80)
                .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
                .animation(.easeInOut(duration: 0.5), value: isGalleryPresented)
                .background(cornerRadius: 8, strokeColor: .primary.opacity(0.1), fill: .background.opacity(0.4))
                .padding(.init(top: 0, leading: 8, bottom: 8, trailing: 8))
            }
        }
        .background(VibrantBackground().ignoresSafeArea(.all))
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.spring) {
                        isGalleryPresented.toggle()
                    }
                } label: {
                    Label("Gallery", systemImage: "inset.filled.bottomhalf.rectangle")
                        .font(.title2)
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isOptionsPresented.toggle()
                    }
                } label: {
                    Label("Options", systemImage: "slider.horizontal.3")
                        .font(.title2)
                }
                .popover(isPresented: $isOptionsPresented) {
                    UpscaleSettingsView()
                        .padding(.top, 12)
                        .overlay(alignment: .topLeading) {
                            Button(action: {
                                withAnimation {
                                    isOptionsPresented = false
                                }
                            }, label: {
                                Image(systemName: "xmark.circle.fill")
                                    .padding(6)
                            })
                            .buttonStyle(.plain)
                        }
                }
            }
        }
        .overlay {
            Rectangle()
                .fill(.blue.opacity(dropOver ? 0.2 : 0))
        }
        .fileImporter(
            isPresented: $isFilePanelPresented,
            allowedContentTypes: [.jpeg, .png, .webP, .folder],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Upscayl.process(urls, by: upscaylData)
            case .failure(let error):
                Common.logger.error("Failed to import files: \(error)")
            }
        }
        .onDrop(of: [.png, .jpeg, .webP], delegate: self)
        .focusable(false)
        .navigationTitle("HiPixel")
        .navigationSubtitle(upscaylData.selectedItem?.fileName ?? "")
    }
    
    func dropEntered(info: DropInfo) {
        withAnimation {
            dropOver = true
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation {
            dropOver = false
        }
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        if info.hasItemsConforming(to: [.png, .jpeg, .webP]) {
            return true
        }
        return false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        
        let queue = DispatchQueue(label: "parsing url ...", attributes: .concurrent)
        let group = DispatchGroup()
        
        var urls = [URL]()
        
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        
        for provider in info.itemProviders(for: [.fileURL]) {
            if !provider.canLoadObject(ofClass: URL.self) {
                continue
            }
            group.enter()
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                defer {
                    group.leave()
                }
                guard let data = item as? Data, let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? else {
                    return
                }
                if !url.hasDirectoryPath && !url.isImageFile {
                    return
                }
                urls.append(url)
            }
        }
        
        group.notify(queue: queue) {
            DispatchQueue.main.async {
                Upscayl.process(urls, by: upscaylData)
            }
        }
        
        return true
    }
}

#Preview {
    ContentView()
}
