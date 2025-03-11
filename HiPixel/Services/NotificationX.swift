//
//  NotificationX.swift
//  HiPixel
//
//  Created by 十里 on 2024/6/22.
//

import Foundation
import SwiftUI
import UserNotifications
import GeneralNotification
import NotchNotification

enum NotificationX {
    static func check() {
        let center = UNUserNotificationCenter.current()
        
        // Call getNotificationSettings method to get current notification settings
        center.getNotificationSettings { settings in
            // In the completionHandler, determine if there's permission based on the value of settings.authorizationStatus
            switch settings.authorizationStatus {
            case .authorized:
                // Has permission, can send and receive notifications
                Common.logger.info("Notification Authorized")
            case .denied:
                // No permission, cannot send and receive notifications
                Common.logger.info("Notification Denied")
            case .notDetermined:
                // Haven't requested permission yet, need to call requestAuthorization method to request permission
                Common.logger.info("Notification Not Determined")
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        Common.logger.info("Notification Authorization has been set!")
                    } else if let error = error {
                        Common.logger.error("\(error.localizedDescription)")
                    }
                }
                Common.logger.info("Notification Determined")
            case .provisional:
                // Temporary authorization, can send and receive silent notifications (won't disturb the user)
                Common.logger.info("Notification Provisional")
            case .ephemeral:
                // Temporary authorization, can send and receive ephemeral notifications (will disappear from the screen)
                Common.logger.info("Notification Ephemeral")
            @unknown default:
                // Unknown status, might be a newly added enum value
                Common.logger.warning("Notification Unknown")
            }
        }
    }
    
    static func push(title: String = "HiPixel", message: String) {
        switch HiPixelConfiguration.shared.notification {
        case .HiPixel:
            GeneralNotification.present(
                bodyView: HStack {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                    
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.headline)
                        Text(message)
                            .font(.caption)
                    }
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .padding(8)
                },
                interval: 3
            )
            NSSound.beep()
        case .Notch:
            NotchNotification.present(
                leadingView: Image(systemName: "bell.fill"),
                trailingView: Image(systemName: "photo.badge.checkmark.fill"),
                bodyView: Text(message).font(.system(size: 11, weight: .medium)),
                interval: 3
            )
            NSSound.beep()
        case .System:
            let content = UNMutableNotificationContent()
            let notificationCenter = UNUserNotificationCenter.current()
            
            notificationCenter.getNotificationSettings { (settings) in
                // Do not schedule notifications if not authorized.
                guard settings.authorizationStatus == .authorized else {
                    notificationCenter.requestAuthorization(options: [.alert, .sound])
                    { (granted, error) in
                        // Enable or disable features based on authorization.
                    }
                    return
                }
            }
            
            content.title = NSLocalizedString(title, comment: "app name")
            content.subtitle = NSLocalizedString(message, comment: "notification message")
            content.sound = UNNotificationSound.default
            
            // show this notification five seconds from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            // add our notification request
            notificationCenter.add(request)
        case .None:
            return
        }
    }
}
