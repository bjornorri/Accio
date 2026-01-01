//
//  UserNotificationPoster.swift
//  Accio
//

import AppKit
import UserNotifications

final class UserNotificationPoster: NSObject, NotificationPoster {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        super.init()
        notificationCenter.delegate = self
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

        let identifier = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request)

        // Remove from notification center after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        }
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

// MARK: - UNUserNotificationCenterDelegate

extension UserNotificationPoster: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner even when app is focused
        completionHandler([.banner])
    }
}
