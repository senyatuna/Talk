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
        
        if isReactionType() {
            handleReaction()
        } else if isReply() {
            handleReply()
        } else {
            handleNormalMessage()
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let content = request?.content {
            contentHandler(content)
        }
    }
}

/// Handlers
extension NotificationService {
    
    private func handleNormalMessage() {
        guard let content = mutableContent else { return }
        content.title = isGroup ? threadName ?? "" : title ?? ""
        content.threadIdentifier = "threadId-\(threadId)"
        contentHandler?(content)
    }
    
    private func handleReaction() {
        guard let content = mutableContent else { return }
        let emoji = Sticker(rawValue: sticker)?.emoji
        content.title = "Reaction"
        let doer = title ?? "Someone"
        content.body = "\(doer) has reacted to a message with \(emoji ?? "")"
        content.categoryIdentifier = "reaction-\(threadId)"
        content.threadIdentifier = "\(threadId)-\(messageId)"
        content.subtitle = ""
        content.sound = nil
        contentHandler?(content)
    }
    
    private func handleReply() {
        guard let content = mutableContent else { return }
        content.title = titleWithGroupIconIfIsGroup()
        content.subtitle = repliedToString() ?? ""
        content.body = makeReplyBody() ?? ""
        content.threadIdentifier = "threadId-\(threadId)"
        content.attachments = []
        contentHandler?(content)
    }
}

/// Helpers
extension NotificationService {
    private func int(key: String) -> Int {
        intValue(forKey: key) ?? -1
    }
    
    private func bool(key: String) -> Bool {
        if let stringValue = stringValue(forKey: key), let boolValue = Bool(stringValue) {
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
    
    private var isGroup: Bool {
        bool(key: "isGroup")
    }
    
    private func titleWithGroupIconIfIsGroup() -> String {
        let title = stringValue(forKey: "title") ?? ""
        return isGroup ? "\(title) 􀉬" : title
    }
    
    private func isReactionType() -> Bool {
        let type = request?.content.userInfo["requestType"] as? String ?? ""
        return type == "reaction"
    }
    
    private func isReply() -> Bool {
        return intValue(forKey: "repliedToMessageMsgId") != nil
    }
    
    private func repliedToString() -> String? {
        let localRepliedToString = isRTL ? repliedToNameFA : repliedToNameEN
        let repliedToName = fullNameReplier() ?? stringValue(forKey: "repliedToMessageSenderUsername") ?? ""
        return "\(localRepliedToString)\(repliedToName)"
    }
    
    private func makeReplyBody() -> String? {
        return "\(stringValue(forKey: "body") ?? "")"
    }
    
    private func fullNameReplier() -> String? {
        let firstName = stringValue(forKey: "repliedToMessageSenderFirstname")
        let lastName = stringValue(forKey: "repliedToMessageSenderLastname")
        guard let firstName = firstName, let lastName = lastName else { return nil }
        return "\(firstName) \(lastName)"
    }
    
    private var mutableContent: UNMutableNotificationContent? {
        request?.content.mutableCopy() as? UNMutableNotificationContent
    }
    
    private var title: String? {
        stringValue(forKey: "title")
    }
    
    private var threadName: String? {
        stringValue(forKey: "threadName")
    }
    
    private var threadId: Int {
        int(key: "threadId")
    }
    
    private var messageId: Int {
        int(key: "msgId")
    }
    
    private var sticker: Int {
        intValue(forKey: "sticker") ?? -1
    }
}


extension NotificationService {
    private var repliedToNameEN : String { "Replid to: " }
    private var repliedToNameFA: String { "2b7Yp9iz2K4g2KjZhzog".fromBase64() ?? "" }
    private var youEN: String { "you" }
    private var youFA: String { "2LTZhdin".fromBase64() ?? "" }
    
    private var isRTL: Bool {
        let groupName = "group.com.lmlvrmedia.leitnerbox"
        let groupUserDefaults = UserDefaults(suiteName: groupName)
        let identifier = groupUserDefaults?.string(forKey: "AppleLanguages")
        return identifier == "ZmFfSVI="
    }
}
