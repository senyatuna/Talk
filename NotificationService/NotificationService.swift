//
//  NotificationService.swift
//  NotificationService
//
//  Created by Xcode on 1/5/26.
//

import UserNotifications
import os.log
import ChatModels
import TalkExtensions

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var request: UNNotificationRequest?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.request = request
                
        let type = request.content.userInfo["requestType"] as? String ?? ""
        if type == "reaction" {
            handleReaction()
        } else {
            contentHandler(request.content)
        }
    }
    
    private func handleReaction() {
        
        let mutableContent = request?.content.mutableCopy() as? UNMutableNotificationContent
        guard
            let userInfo = request?.content.userInfo,
            let stickerValue = userInfo["sticker"] as? String,
            let stickerInt = Int(stickerValue),
            let content = mutableContent
        else { return }
        
        let emoji = Sticker(rawValue: stickerInt)?.emoji
        content.title = "Reaction"
        let doer = userInfo["title"] as? String ?? "Someone"
        content.body = "\(doer) has reacted to a message with \(emoji ?? "")"
        content.subtitle = ""
        content.sound = nil
        contentHandler?(content)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let content = request?.content {
            contentHandler(content)
        }
    }
}
