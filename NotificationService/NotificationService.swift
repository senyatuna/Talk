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
    var wrapper: NotificationRequestWrapper?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.request = request
        let wrapper = NotificationRequestWrapper(request: request)
        self.wrapper = wrapper
        
        if wrapper.isReactionType() {
            handleReaction()
        } else if wrapper.isReply() {
            handleReply()
        } else if wrapper.isEditMessage() {
            Task { await handleEditMessage() }
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
        guard let wrapper = wrapper, let content = wrapper.mutableContent else { return }
        content.title = wrapper.isGroup ? wrapper.threadName ?? "" : wrapper.title ?? ""
        content.threadIdentifier = "threadId-\(wrapper.threadId)"
        if let groupIconAttachment = wrapper.groupIconAttachment {
            content.attachments = [groupIconAttachment]
        }
        contentHandler?(content)
    }
    
    private func handleReaction() {
        guard let wrapper = wrapper, let content = wrapper.mutableContent else { return }
        let emoji = Sticker(rawValue: wrapper.sticker)?.emoji
        content.title = "Reaction"
        let doer = wrapper.title ?? "Someone"
        content.body = "\(doer) has reacted to a message with \(emoji ?? "")"
        content.categoryIdentifier = "reaction-\(wrapper.threadId)"
        content.threadIdentifier = "\(wrapper.threadId)-\(wrapper.messageId)"
        content.subtitle = ""
        content.sound = nil
        contentHandler?(content)
    }
    
    private func handleReply() {
        guard let wrapper = wrapper, let content = wrapper.mutableContent else { return }
        content.title = wrapper.titleWithGroupIconIfIsGroup()
        content.subtitle = wrapper.repliedToString() ?? ""
        content.body = wrapper.makeReplyBody() ?? ""
        content.threadIdentifier = "threadId-\(wrapper.threadId)"
        
        if let groupIconAttachment = wrapper.groupIconAttachment {
            content.attachments = [groupIconAttachment]
        }
        contentHandler?(content)
    }
    
    private func handleEditMessage() async {
        guard let wrapper = wrapper else { return }
        let currentRequestMessageId = wrapper.requestMessageId(request)
        let notifs = await UNUserNotificationCenter.current().deliveredNotifications()
        let notif = notifs.first(where: { wrapper.requestMessageId($0.request) == currentRequestMessageId })
        if let request = notif?.request {
            /// Remove current delivered notification
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [request.identifier])
            
            /// Add new notification
            if let newContent = wrapper.mutableContent {
                newContent.title = wrapper.isGroup ? wrapper.threadName ?? "" : wrapper.title ?? ""
                newContent.subtitle = wrapper.isRTL ? wrapper.editedFA : wrapper.editedEN
                newContent.threadIdentifier = "threadId-\(wrapper.threadId)"
                contentHandler?(newContent)
            } else {
                contentHandler?(request.content)
            }
        }
    }
}
