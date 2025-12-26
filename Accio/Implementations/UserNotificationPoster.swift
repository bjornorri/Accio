//
//  UserNotificationPoster.swift
//  Accio
//

import AppKit
import UserNotifications

final class UserNotificationPoster: NotificationPoster {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        requestAuthorization()
    }

    private func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert]) { _, _ in }
    }

    func postAppLaunchingNotification(appName: String, icon: NSImage?) {
        let content = UNMutableNotificationContent()
        content.title = appName
        content.subtitle = "Launching..."

        if let icon, let attachment = createAttachment(from: icon) {
            content.attachments = [attachment]
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request)
    }

    private func createAttachment(from image: NSImage) -> UNNotificationAttachment? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        do {
            try pngData.write(to: tempURL)
            return try UNNotificationAttachment(identifier: UUID().uuidString, url: tempURL)
        } catch {
            return nil
        }
    }
}
