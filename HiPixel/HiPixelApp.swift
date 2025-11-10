//
//  HiPixelApp.swift
//  HiPixel
//
//  Created by 十里 on 2024/6/16.
//

import Sparkle
import SwiftUI
import SettingsAccess

@main
struct HiPixelApp: App {

    @AppStorage(HiPixelConfiguration.Keys.ColorScheme)
    var colorScheme: HiPixelConfiguration.ColorScheme = .system

    @AppStorage(HiPixelConfiguration.Keys.ShowMenuBarExtra)
    var showMenuBarExtra: Bool = false

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
                .openSettingsAccess()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(.init(width: 720, height: 480))
        .defaultPosition(.center)
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

        MenuBarExtra("HiPixel", image: "MenuBarIcon", isInserted: $showMenuBarExtra) {
            MenuBarExtraView(updater: updaterController.updater)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppIconManager.shared.applyAppIcon()
        MonitorService.shared.load()
        // Apply dock icon setting on launch
        _ = DockIconService.shared.setDockIconHidden(HiPixelConfiguration.shared.hideDockIcon)
        
        // Handle silent launch - hide main window if enabled
        if HiPixelConfiguration.shared.launchSilently {
            // Hide all windows on silent launch
            DispatchQueue.main.async {
                NSApplication.shared.windows.forEach { window in
                    if window.title == "HiPixel" {
                        window.orderOut(nil)
                    }
                }
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { url in
            URLSchemeHandler.shared.handle(url)
        }
    }
}

struct MenuBarExtraView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Button("Main Window") {
            showMainWindow()
        }
        
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text("Settings...")
            }
        } else {
            Button("Settings...") {
                showSettingsWindow()
            }
        }
        
        Button("Check for Updates…") {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
        
        Divider()
        
        Button("Quit HiPixel") {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func showMainWindow() {
        // Activate the app first
        NSApp.activate(ignoringOtherApps: true)
        
        // Find the main window by title
        if let window = NSApplication.shared.windows.first(where: { $0.title == "HiPixel" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // If no window exists, use openWindow to create a new one
            openWindow(id: "HiPixel")
        }
    }
    
    private func showSettingsWindow() {
        // Open settings window using standard macOS action
        NSApp.activate(ignoringOtherApps: true)
        // Use performSelector to avoid Selector warning
        let selector: Selector
        if #available(macOS 13.0, *) {
            selector = NSSelectorFromString("showSettingsWindow:")
        } else {
            selector = NSSelectorFromString("showPreferencesWindow:")
        }
        if NSApp.responds(to: selector) {
            NSApp.perform(selector, with: nil)
        }
    }
}
