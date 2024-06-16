//
//  HiPixelApp.swift
//  HiPixel
//
//  Created by 十里 on 2024/6/16.
//

import SwiftUI

@main
struct HiPixelApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
