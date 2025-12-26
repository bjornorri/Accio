//
//  NotificationPoster.swift
//  Accio
//

import AppKit

protocol NotificationPoster {
    func postAppLaunchingNotification(appName: String, icon: NSImage?)
}
