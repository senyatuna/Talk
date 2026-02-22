//
//  UNUserNotificationCenter+.swift
//  Talk
//
//  Created by Xcode on 2/22/26.
//
import Foundation
import UserNotifications

extension UNUserNotificationCenter {
    static func findNotif(messageId: Int) async -> UNNotification? {
        let notifs = await UNUserNotificationCenter.current().deliveredNotifications()
        let notif = notifs.first(where: { NotificationRequestWrapper(request: $0.request).messageId == messageId })
        return notif
    }
}
