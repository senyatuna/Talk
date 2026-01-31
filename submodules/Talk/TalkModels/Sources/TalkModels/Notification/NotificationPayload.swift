//
//  NotificationPayload.swift
//  TalkModels
//
//  Created by Xcode on 1/5/26.
//

import UIKit
import Chat

public struct NotificationPayload: Codable {
    public let requestType: NotificationPayloadRequestType?
    public let threadId: Int?
    public let title: String?
    public let body: String?
    public let msgId: Int?
    public let messageType: ChatModels.MessageType?
    public let appId: String?
    public let asp: NotificationPayloadAPS?
    public let time: UInt?
    public let uniqueId: String?
    public let isGroup: Bool?
    public let threadType: ThreadTypes?
    public let chatMessageId: Int?
    public let timeNanos: Int?
    public let gcmMessageId: Int?
    public let googleFId: String?
    public let googleSenderId: Int?
    public let googleCAE: Int?
    public let senderImage: String?
    
    public enum CodingKeys: String, CodingKey {
        case requestType = "requestType"
        case threadId = "threadId"
        case title = "title"
        case body = "body"
        case msgId = "msgId"
        case messageType = "messageType"
        case appId = "appId"
        case asp = "asp"
        case time = "time"
        case uniqueId = "messageId"
        case isGroup = "isGroup"
        case threadType = "threadType"
        case chatMessageId = "chatMessageId"
        case timeNanos = "timeNanos"
        case gcmMessageId = "gcmMessageId"
        case googleFId = "googleFId"
        case googleSenderId = "googleSenderId"
        case googleCAE = "googleCAE"
        case senderImage = "senderImage"
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.requestType, forKey: .requestType)
        try container.encodeIfPresent(self.threadId, forKey: .threadId)
        try container.encodeIfPresent(self.title, forKey: .title)
        try container.encodeIfPresent(self.body, forKey: .body)
        try container.encode(self.msgId, forKey: .msgId)
        try container.encodeIfPresent(self.messageType, forKey: .messageType)
        try container.encodeIfPresent(self.appId, forKey: .appId)
        try container.encodeIfPresent(self.asp, forKey: .asp)
        try container.encode(self.time, forKey: .time)
        try container.encode(self.uniqueId, forKey: .uniqueId)
        try container.encode(self.isGroup, forKey: .isGroup)
        try container.encodeIfPresent(self.threadType, forKey: .threadType)
        try container.encodeIfPresent(self.chatMessageId, forKey: .chatMessageId)
        try container.encodeIfPresent(self.timeNanos, forKey: .timeNanos)
        try container.encodeIfPresent(self.gcmMessageId, forKey: .gcmMessageId)
        try container.encodeIfPresent(self.googleFId, forKey: .googleFId)
        try container.encodeIfPresent(self.googleSenderId, forKey: .googleSenderId)
        try container.encodeIfPresent(self.googleCAE, forKey: .googleCAE)
        try container.encodeIfPresent(self.senderImage, forKey: .senderImage)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.requestType = try container.decode(NotificationPayloadRequestType.self, forKey: .requestType)
        self.threadId = NotificationPayload.toNS(container, .threadId)?.intValue
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.body = try container.decodeIfPresent(String.self, forKey: .body)
        self.msgId = NotificationPayload.toNS(container, .msgId)?.intValue
        if let messageTypeString = try container.decodeIfPresent(String.self, forKey: .messageType),
           let messageTypeInt = Int(messageTypeString) {
            messageType = MessageType(rawValue: messageTypeInt)
        } else {
            messageType = nil
        }
        
        if let threadTypeString = try container.decodeIfPresent(String.self, forKey: .messageType), let threadTypeInt = Int(threadTypeString) {
            threadType = ThreadTypes(rawValue: threadTypeInt)
        } else {
            threadType = nil
        }
        
        self.appId = try container.decodeIfPresent(String.self, forKey: .appId)
        self.asp = try container.decodeIfPresent(NotificationPayloadAPS.self, forKey: .asp)
        self.time = NotificationPayload.toNS(container, .time)?.uintValue
        self.uniqueId = try container.decode(String.self, forKey: .uniqueId)
        self.isGroup = NotificationPayload.toNS(container, .isGroup)?.boolValue
        self.chatMessageId = NotificationPayload.toNS(container, .chatMessageId)?.intValue
        self.timeNanos = NotificationPayload.toNS(container, .timeNanos)?.intValue
        self.gcmMessageId = NotificationPayload.toNS(container, .gcmMessageId)?.intValue
        self.googleFId = try container.decodeIfPresent(String.self, forKey: .googleFId)
        self.googleSenderId = NotificationPayload.toNS(container, .googleSenderId)?.intValue
        self.googleCAE = NotificationPayload.toNS(container, .googleCAE)?.intValue
        self.senderImage = try container.decodeIfPresent(String.self, forKey: .senderImage)
    }

    private static func toNS(_ container: KeyedDecodingContainer<NotificationPayload.CodingKeys>, _ key: CodingKeys) -> NSNumber? {
        guard let stringValue = try? container.decodeIfPresent(String.self, forKey: key) else { return nil }
        let value = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // Bool
        if let boolValue = Bool(value.lowercased()) {
            return NSNumber(value: boolValue)
        }

        // Int
        if let intValue = Int(value) {
            return NSNumber(value: intValue)
        }

        // UInt
        if let uintValue = UInt(value) {
            return NSNumber(value: uintValue)
        }

        // Double (optional, but usually helpful)
        if let doubleValue = Double(value) {
            return NSNumber(value: doubleValue)
        }

        return nil
    }
}

public struct NotificationPayloadAPS: Codable {
    public let alert: NotificationPayloadAPSAlert
    
    public enum CodingKeys: String, CodingKey {
        case alert = "alert"
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.alert, forKey: .alert)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.alert = try container.decode(NotificationPayloadAPSAlert.self, forKey: .alert)
    }
}

public struct NotificationPayloadAPSAlert: Codable {
    public let title: String?
    public let body: String?
    
    public init(title: String?, body: String?) {
        self.title = title
        self.body = body
    }
    
    public enum CodingKeys: String, CodingKey {
        case title = "title"
        case body = "body"
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.title, forKey: .title)
        try container.encodeIfPresent(self.body, forKey: .body)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.body = try container.decodeIfPresent(String.self, forKey: .body)
    }
}

public enum NotificationPayloadRequestType: String, Codable {
    case reaction = "reaction"
    case sendMessage = "sendMessage"
}
