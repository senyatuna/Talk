//
//  NotificationRequestWrapper.swift
//  NotificationService
//
//  Created by Xcode on 2/9/26.
//

import UserNotifications

class NotificationRequestWrapper {
    let request: UNNotificationRequest
    
    init(request: UNNotificationRequest) {
        self.request = request
    }
}

/// Helpers
extension NotificationRequestWrapper {
    func int(key: String) -> Int {
        intValue(forKey: key) ?? -1
    }
    
    func bool(key: String) -> Bool {
        if let stringValue = stringValue(forKey: key), let boolValue = Bool(stringValue) {
            return boolValue
        }
        return false
    }
    
    func intValue(forKey key: String) -> Int? {
        if let stringValue = request.content.userInfo[key] as? String, let intValue = Int(stringValue) {
            return intValue
        }
        return nil
    }
    
    func stringValue(forKey key: String) -> String? {
        if let stringValue = request.content.userInfo[key] as? String {
            return stringValue
        }
        return nil
    }
    
    var isGroup: Bool {
        bool(key: "isGroup")
    }
    
    func titleWithGroupIconIfIsGroup() -> String {
        let title = stringValue(forKey: "title") ?? ""
        return isGroup ? "\(title)" : title
    }
    
    func isReply() -> Bool {
        return intValue(forKey: "repliedToMessageMsgId") != nil
    }
    
    func requestType() -> RequestType {
        let type = request.content.userInfo["requestType"] as? String ?? ""
        return RequestType(rawValue: type) ?? .none
    }
    
    func requestMessageId(_ request: UNNotificationRequest?) -> Int? {
        guard let msgId = request?.content.userInfo["msgId"] as? String else { return nil }
        return Int(msgId)
    }
    
    func repliedToString() -> String? {
        let localRepliedToString = isRTL ? repliedToNameFA : repliedToNameEN
        let repliedToName = fullNameReplier() ?? stringValue(forKey: "repliedToMessageSenderUsername") ?? ""
        return "\(localRepliedToString)\(repliedToName)"
    }
    
    func makeReplyBody() -> String? {
        return "\(stringValue(forKey: "body") ?? "")"
    }
    
    func fullNameReplier() -> String? {
        let firstName = stringValue(forKey: "repliedToMessageSenderFirstname")
        let lastName = stringValue(forKey: "repliedToMessageSenderLastname")
        guard let firstName = firstName, let lastName = lastName else { return nil }
        return "\(firstName) \(lastName)"
    }
    
    var groupIconAttachment: UNNotificationAttachment? {
        guard
            isGroup,
            let groupIconURL: URL = Bundle.main.url(forResource: "ic_group", withExtension: "png"),
            let attachment = try? UNNotificationAttachment(identifier: "groupIcon", url: groupIconURL, options: nil)
        else { return nil }
        return attachment
    }
    
    var mutableContent: UNMutableNotificationContent? {
        request.content.mutableCopy() as? UNMutableNotificationContent
    }
    
    var title: String? {
        stringValue(forKey: "title")
    }
    
    var threadName: String? {
        stringValue(forKey: "threadName")
    }
    
    var threadId: Int {
        int(key: "threadId")
    }
    
    var messageId: Int {
        int(key: "msgId")
    }
    
    var sticker: Int {
        intValue(forKey: "sticker") ?? -1
    }
}

extension NotificationRequestWrapper {
    var repliedToNameEN : String { "Replid to: " }
    var repliedToNameFA: String { "2b7Yp9iz2K4g2KjZhzog".fromBase64() ?? "" }
    var youEN: String { "you" }
    var youFA: String { "2LTZhdin".fromBase64() ?? "" }
    var editedEN: String { "(Edited ✏️)" }
    var editedFA: String { "KNin2LXZhNin2K0g2LTYr+Kcj++4jyk=".fromBase64() ?? "" }
    
    var isRTL: Bool {
        let groupName = "group.com.lmlvrmedia.leitnerbox"
        let groupUserDefaults = UserDefaults(suiteName: groupName)
        let defaultLanguage = groupUserDefaults?.string(forKey: "DefaultGroupLanguage")
        return defaultLanguage == "ZmFfSVI=".fromBase64() ?? ""
    }
}

enum RequestType: String {
    case sendMessage = "sendMessage"
    case editMessage = "editMessage"
    case seeMessage = "seeMessage"
    case reaction = "reaction"
    case none
}
