//
//  NotificationService.swift
//  NotificationService
//
//  Created by Xcode on 1/5/26.
//

import UserNotifications
import os.log

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
//        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
//        bestAttemptContent?.title = "tamptered"
        contentHandler(bestAttemptContent!)
        
        os_log("🔥🔥 Notification Service Extension DID RECEIVE")

        let userInfo = request.content.userInfo
        if let requestType = userInfo["requestType"] as? String, requestType != "sendMessage" {
            /// Do nothing if the requestType is reaction type,
            /// so we do not need to call contentHandler callback,
            /// therefore there will be no notification even in background.
            contentHandler(UNMutableNotificationContent())
            return
        } else {
            contentHandler(request.content)
        }
//
//        guard let bestAttemptContent = bestAttemptContent else {
//            /// Default content handling
//            contentHandler(request.content)
//            return
//        }
//      
//
//        /// Normal notification
//        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
