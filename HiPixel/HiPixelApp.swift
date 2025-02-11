//
//  HiPixelApp.swift
//  HiPixel
//
//  Created by 十里 on 2024/6/16.
//

import SwiftUI
import Sparkle

@main
struct HiPixelApp: App {
    
    @AppStorage(HiPixelConfiguration.Keys.ColorScheme)
    var colorScheme: HiPixelConfiguration.ColorScheme = .system
    
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    
    @State private var aboutWindow: NSWindow?

    @StateObject var upscaylData = UpscaylData.shared
    
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
    
    var body: some Scene {
        Window("HiPixel", id: "HiPixel") {
            ContentView()
                .frame(minWidth: 640, idealWidth: 720, minHeight: 480, idealHeight: 640)
                .onAppear {
                    HiPixelConfiguration.ColorScheme.change(to: colorScheme)
                }
                .onChange(of: colorScheme) { newValue in
                    HiPixelConfiguration.ColorScheme.change(to: newValue)
                }
                .environmentObject(upscaylData)
                .ignoresSafeArea(.all)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(.init(width: 720, height: 480))
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About") {
                    AboutWindowController.shared.showWindow(nil)
                }
            }
            
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            
            CommandGroup(after: .toolbar) {
                Picker("Appearance", selection: $colorScheme) {
                    ForEach(HiPixelConfiguration.ColorScheme.allCases, id: \.self) {
                        Text($0.localized)
                            .tag($0)
                    }
                }
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try ResourceManager.prepareModels()
        } catch {
            print("Failed to prepare models: \(error)")
        }
        AppIconManager.shared.applyAppIcon()
//        SoundManager.shared.loadSound(named: "Blow", volume: 0.2)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { url in
            URLSchemeHandler.shared.handle(url)
        }
    }
}
