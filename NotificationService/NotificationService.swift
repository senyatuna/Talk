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
        } else if let newContent = request.content.mutableCopy() as? UNMutableNotificationContent {
            newContent.title = bool(key: "isGroup") ? stringValue(forKey: "threadName") ?? "" : stringValue(forKey: "title") ?? ""
            newContent.threadIdentifier = "threadId-\(int(key: "threadId"))"
            contentHandler(newContent)
        }
    }
    
    private func handleReaction() {
        
        let mutableContent = request?.content.mutableCopy() as? UNMutableNotificationContent
        guard let content = mutableContent else { return }
        
        let sticker = intValue(forKey: "sticker") ?? -1
        let emoji = Sticker(rawValue: sticker)?.emoji
        content.title = "Reaction"
        let doer = stringValue(forKey: "title") ?? "Someone"
        content.body = "\(doer) has reacted to a message with \(emoji ?? "")"
        content.categoryIdentifier = "reaction-\(int(key: "threadId"))"
        content.threadIdentifier = "\(int(key: "threadId"))-\(int(key: "msgId"))"
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

extension NotificationService {
    private func int(key: String) -> Int {
       intValue(forKey: key) ?? -1
    }
    
    private func bool(key: String) -> Bool {
        if let stringValue = stringValue(forKey: "isGroup"), let boolValue = Bool(stringValue) {
            return boolValue
        }
        return false
    }
    
    private func intValue(forKey key: String) -> Int? {
        if let stringValue = request?.content.userInfo[key] as? String, let intValue = Int(stringValue) {
            return intValue
        }
        return nil
    }
    
    private func stringValue(forKey key: String) -> String? {
        if let stringValue = request?.content.userInfo[key] as? String {
            return stringValue
        }
        return nil
    }
}
