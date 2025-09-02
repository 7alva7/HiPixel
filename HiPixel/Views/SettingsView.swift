//
//  SettingsView.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/22.
//

import SwiftUI

struct SettingsView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("General Settings")
                }
                .tag(0)

            AdvancedSettingsView()
                .tabItem {
                    Image(systemName: "bolt.square.fill")
                    Text("Advanced")
                }
                .tag(1)

            AboutView()
                .tabItem {
                    Image(systemName: "info.square.fill")
                    Text("About")
                }
                .tag(2)

            DonationView()
                .tabItem {
                    Image(systemName: "heart.square.fill")
                    Text("Support")
                }
                .tag(3)
        }
        .frame(width: 360)
        .navigationTitle("Settings")
        .background(VibrantBackground())
        .focusable(false)
    }
}

struct GeneralSettingsView: View {

    @AppStorage(HiPixelConfiguration.Keys.ColorScheme)
    var colorScheme: HiPixelConfiguration.ColorScheme = .system

    @AppStorage(HiPixelConfiguration.Keys.NotificationMode)
    var notification: HiPixelConfiguration.NotificationMode = .None

    @AppStorage(HiPixelConfiguration.Keys.SelectedAppIcon)
    private var selectedAppIcon: HiPixelConfiguration.AppIcon = .primary

    var body: some View {
        VStack {
            SettingItem(
                title: "APP ICON",
                icon: "app.badge",
                bodyView: VStack(spacing: 0) {
                    ForEach(HiPixelConfiguration.AppIcon.allCases, id: \.rawValue) { icon in
                        HStack {
                            if let image = icon.previewImage {
                                Image(nsImage: image)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                            }

                            Text(icon.displayName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.caption)
                                .foregroundStyle(selectedAppIcon == icon ? .white : .secondary)

                            if selectedAppIcon == icon {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(6)
                        .background {
                            if selectedAppIcon == icon {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "#55AAEF")!,
                                                .blue,
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 8).fill(.background.opacity(0.01))
                            }
                        }
                        .overlay {
                            if selectedAppIcon == icon {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.4), .clear,
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        }
                        .onTapGesture {
                            selectedAppIcon = icon
                            AppIconManager.shared.setAppIcon(icon)
                        }
                    }
                }.padding(.leading, 8)
            )

            SettingItem(
                title: "Appearance",
                icon: "sun.lefthalf.filled",
                trailingView: Group {
                    Picker("", selection: $colorScheme) {
                        ForEach(HiPixelConfiguration.ColorScheme.allCases, id: \.self) {
                            Text($0.localized)
                                .tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.caption)
                }
            )

            SettingItem(
                title: "Notification",
                icon: "bell",
                trailingView: Group {
                    HStack(spacing: 4) {
                        if notification == .HiPixel || notification == .Notch {
                            Button(
                                action: {
                                    NotificationX.push(message: "")
                                },
                                label: {
                                    Image(systemName: "eye")
                                }
                            )
                            .buttonStyle(.plain)
                        }
                        Picker("", selection: $notification) {
                            ForEach(HiPixelConfiguration.NotificationMode.allCases, id: \.self) {
                                Text($0.localized)
                                    .tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .font(.caption)
                }
            )
        }
        .padding(12)
    }
}

struct AdvancedSettingsView: View {

    @ObservedObject var monitorService = MonitorService.shared
    @StateObject private var downloadManager = ResourceDownloadManager.shared

    var body: some View {
        VStack {
            SettingItem(
                title: "HiPixel Automatically",
                icon: "square.stack.3d.up.badge.automatic",
                description: "HiPixel will automatically process new images monitored in the selected folder.",
                trailingView: Group {
                    Button(
                        action: {
                            Common.openPanel(
                                message: String(localized: "Select a folder to auto-hipixel new images"),
                                windowTitle: "HiPixel"
                            ) { url in
                                let item = MonitorItem(url: url)
                                monitorService.add(item)
                            }
                        },
                        label: {
                            Image(systemName: "plus")
                        }
                    )
                    .buttonStyle(.plain)
                },
                bodyView: VStack(spacing: 4) {
                    ForEach(monitorService.items) { item in
                        MonitiorItemView(monitorService: monitorService, item: item)
                    }
                }
            )
            
            SettingItem(
                title: "Dependencies",
                icon: "cube.box",
                description: "AI models and processing tools version.",
                trailingView: Group {
                    Button(action: {
                        Task {
                            await downloadManager.checkForUpdates()
                        }
                    }, label: {
                        Image(systemName: "arrow.trianglehead.2.counterclockwise")
                            
                    })
                    .buttonStyle(.plain)
                    .disabled(downloadManager.downloadState == .checking ||
                              downloadManager.downloadState == .installing ||
                              isDownloading(downloadManager.downloadState))
                },
                bodyView: VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Version:")
                            .foregroundColor(.secondary)
                        
                        Text(downloadManager.currentVersion.isEmpty ? "Unknown" : downloadManager.currentVersion)
                            .fontWeight(.medium)
                            .foregroundColor(downloadManager.currentVersion == "Not installed" ? .secondary : .primary)
                        Spacer()
                        // Status indicator on the right
                        switch downloadManager.downloadState {
                        case .checking:
                            ProgressView()
                                .scaleEffect(0.34)
                        case .downloading(let resource):
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.34)
                                Text("Downloading \(resource)...")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        case .installing:
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.34)
                                Text("Installing...")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        case .completed:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(LinearGradient(
                                    colors: [
                                        Color(hex: "#55AAEF") ?? Color.blue.opacity(0.8),
                                        .blue
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .font(.caption)
                        case .error(_):
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(LinearGradient(
                                    colors: [
                                        .pink.opacity(0.8),
                                        .pink
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .font(.caption)
                        default:
                            EmptyView()
                        }
                    }
                    .font(.caption)
                    
                    // Progress bar only during download
                    if case .downloading(_) = downloadManager.downloadState {
                        VStack(alignment: .leading, spacing: 2) {
                            ProgressView(value: downloadManager.downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                            HStack {
                                Text("\(Int(downloadManager.downloadProgress * 100))%")
                                    .font(.caption)
                                Spacer()
                                if !downloadManager.downloadSpeed.isEmpty {
                                    Text(downloadManager.downloadSpeed)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            )
        }
        .padding(12)
        .onAppear {
            // Check resource status when view appears
            Task {
                await downloadManager.downloadResourcesIfNeeded()
            }
        }
    }
    
    private func isDownloading(_ state: ResourceDownloadManager.DownloadState) -> Bool {
        if case .downloading(_) = state {
            return true
        }
        return false
    }
}

struct UpscaleSettingsView: View {

    @AppStorage(HiPixelConfiguration.Keys.UpscaylModel)
    var upscaleModel: HiPixelConfiguration.UpscaylModel = .Upscayl_Standard

    @AppStorage(HiPixelConfiguration.Keys.SaveImageAs)
    var saveImageAs: HiPixelConfiguration.ImageFormat = .png

    @AppStorage(HiPixelConfiguration.Keys.ImageScale)
    var imageScale: Double = 4.0

    @AppStorage(HiPixelConfiguration.Keys.ImageCompression)
    var imageCompression: Int = 0

    @AppStorage(HiPixelConfiguration.Keys.EnableZipicCompression)
    var enableZipicCompression: Bool = false

    @AppStorage(HiPixelConfiguration.Keys.EnableSaveOutputFolder)
    var enableSaveOutputFolder: Bool = false

    @AppStorage(HiPixelConfiguration.Keys.SaveOutputFolder)
    var saveOutputFolder: String?

    @AppStorage(HiPixelConfiguration.Keys.OverwritePreviousUpscale)
    var overwritePreviousUpscale: Bool = false

    @AppStorage(HiPixelConfiguration.Keys.GPUID)
    var gpuID: String = ""

    @AppStorage(HiPixelConfiguration.Keys.CustomTileSize)
    var customTileSize: Int = 0

    @AppStorage(HiPixelConfiguration.Keys.CustomModelsFolder)
    var customModelsFolder: String?

    @AppStorage(HiPixelConfiguration.Keys.EnableTTA)
    var enableTTA: Bool = false

    @State private var showZipicInstallAlert = false

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }

    var body: some View {
        VStack {
            SettingItem(
                title: "Select Model",
                icon: "wand.and.stars",
                description: HiPixelConfiguration.UpscaylModel.description,
                trailingView: Group {
                    Picker("", selection: $upscaleModel) {
                        ForEach(HiPixelConfiguration.UpscaylModel.allCases, id: \.self) {
                            Text($0.text)
                                .tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                }
            )

            SettingItem(
                title: "SAVE IMAGE AS",
                icon: "photo",
                description: "The format in which the image will be saved.",
                trailingView: Group {
                    Picker("", selection: $saveImageAs) {
                        ForEach(HiPixelConfiguration.ImageFormat.allCases, id: \.self) {
                            Text($0.localized)
                                .tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                }
            )

            SettingItem(
                title: "IMAGE SCALE",
                icon: "slider.horizontal.below.rectangle",
                description:
                    "Anything above 4X (except 16X Double HiPixel) only resizes the image and does not use AI upscaling.",
                trailingView: Group {
                    Text("X\(imageScale, specifier: "%.0f")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                },
                bodyView: VStack(spacing: 6) {

                    Slider(
                        value: $imageScale,
                        in: 2...16,
                        step: 1.0
                    )

                    HStack {
                        Text("X2")
                        Spacer()
                        Text("x16")
                    }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)

                    if imageScale >= 6 {
                        Text("This may cause performance issues on some devices.")
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            )

            SettingItem(
                title: "IMAGE COMPRESSION",
                icon: "rectangle.compress.vertical",
                description:
                    "PNG compression is lossless, so it might not reduce the file size significantly and higher compression values might affect the performance. JPG and WebP compression is lossy",
                bodyView: VStack(spacing: 6) {
                    HStack {
                        Text("\(imageCompression)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Toggle(
                            "Compress with Zipic",
                            isOn: Binding(
                                get: { enableZipicCompression },
                                set: { newValue in
                                    if newValue
                                        && !AppInstallationChecker.isAppInstalled(bundleIdentifier: "studio.5km.zipic")
                                    {
                                        showZipicInstallAlert = true
                                        enableZipicCompression = false
                                    } else {
                                        enableZipicCompression = newValue
                                    }
                                }
                            )
                        )
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(imageCompression) },
                            set: { imageCompression = Int($0) }
                        ),
                        in: 0...90,
                        step: 10
                    )
                    .onChange(of: imageCompression) { newValue in
                        // 确保值在 0-90 范围内
                        imageCompression = min(90, max(0, newValue))
                    }

                    HStack {
                        Text("0")
                        Spacer()
                        Text("90")
                    }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
                }
            )
            .alert("Install Zipic", isPresented: $showZipicInstallAlert) {
                Button("Install") {
                    AppInstallationChecker.openAppStore(url: "https://zipic.app")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Zipic is not installed. Would you like to install it now?")
            }
            
            SettingItem(
                title: "TTA (Test-Time Augmentation)",
                icon: "wand.and.rays",
                description: "TTA (Test-Time Augmentation): Runs multiple flipped/rotated passes and merges them to reduce noise/artifacts and clean edges; ~8× slower and may look slightly softer.",
                trailingView: Group {
                    Toggle("", isOn: $enableTTA)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            )

            SettingItem(
                title: "OUTPUT FOLDER",
                icon: "folder",
                trailingView: Group {
                    Toggle("", isOn: $enableSaveOutputFolder)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                },
                bodyView: HStack {
                    if enableSaveOutputFolder {
                        Text(saveOutputFolder == nil ? "Set the output folder" : saveOutputFolder!)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .truncationMode(.middle)

                        Spacer()

                        Button(
                            action: {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = false
                                panel.canChooseDirectories = true
                                panel.allowsMultipleSelection = false
                                panel.allowedContentTypes = [.folder]
                                panel.canCreateDirectories = true
                                panel.begin { result in
                                    if result == NSApplication.ModalResponse.OK, let url = panel.url {
                                        saveOutputFolder = url.path
                                    }
                                }
                            },
                            label: {
                                Image(systemName: "folder.badge.gear")
                            }
                        )
                        .buttonStyle(.plain)
                    }
                }
            )

            SettingItem(
                title: "OVERWRITE PREVIOUS UPSCALE",
                icon: "photo.stack",
                description: "If enabled, HiPixel will process the image again instead of loading it directly.",
                trailingView: Group {
                    Toggle("", isOn: $overwritePreviousUpscale)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            )

            SettingItem(
                title: "GPU ID",
                icon: "cpu",
                description:
                    "Please read the **[Upscayl Documentation](https://github.com/upscayl/upscayl/wiki/Guide#gpu-id)** for more information.",
                bodyView: Group {
                    TextField("Set the GPU ID", text: $gpuID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(cornerRadius: 6)
                }
            )

            SettingItem(
                title: "CUSTOM TILE SIZE",
                icon: "square.grid.3x3.square",
                description:
                    "Use a custom tile size for segmenting the image. This can help process images faster by reducing the number of tiles generated.",
                trailingView: HStack(spacing: 6) {
                    if customTileSize == 0 {
                        Text("Auto")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                    TextField(
                        "\(customTileSize,specifier: "%.0f")",
                        value: $customTileSize,
                        formatter: numberFormatter
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(cornerRadius: 6)
                }
            )

            Button(
                action: {
                    HiPixelConfiguration.shared.reset()
                },
                label: {
                    HStack {
                        Spacer()
                        Label("RESET OPTIONS", systemImage: "arrow.counterclockwise")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            )
            .buttonStyle(.gradient(configuration: .danger))
        }
        .padding(12)
    }
}

struct DonationView: View {
    @State private var showAlipayQR = false
    @State private var showWeChatQR = false
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.pink.gradient)
                    .scaleEffect(heartScale)
                    .onAppear {
                        heartScale = 1.0
                        withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                            heartScale = 1.2
                        }
                    }

                Text("Support HiPixel")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Your support means a lot")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    if let url = URL(string: "https://www.buymeacoffee.com/okooo5km") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(.bmc)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                        Text("Buy Me a Coffee")
                            .font(.headline)
                    }
                    .frame(width: 200)
                }
                .buttonStyle(.gradient(configuration: .buyMeACoffee))

                Button {
                    showAlipayQR.toggle()
                } label: {
                    HStack {
                        Image(.alipay)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                        Text("Alipay")
                            .font(.headline)
                    }
                    .frame(width: 200)
                }
                .buttonStyle(.gradient(configuration: .alipay))
                .popover(isPresented: $showAlipayQR) {
                    Image(.alipayQr)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280)
                }

                Button {
                    showWeChatQR.toggle()
                } label: {
                    HStack {
                        Image(.wechatpay)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                        Text("WeChat Pay")
                            .font(.headline)
                    }
                    .frame(width: 200)
                }
                .buttonStyle(.gradient(configuration: .wechatPay))
                .popover(isPresented: $showWeChatQR) {
                    Image(.wechatpayQr)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280)
                }
            }

            Text("Thank you for your support! ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
