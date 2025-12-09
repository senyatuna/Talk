//
//  NotificationRegisterationRequest.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation

public struct NotificationRegisterationRequest: Encodable {
    let isSubscriptionRequest: Bool
    let registrationToken: String
    let appId: String
    let platform: String
    let deviceId: String
    let ssoId: Int
    let packageName: String

    public init(
        isSubscriptionRequest: Bool = true,
        registrationToken: String,
        appId: String,
        platform: String = "IOS",
        deviceId: String,
        ssoId: Int,
        packageName: String
    ) {
        self.isSubscriptionRequest = isSubscriptionRequest
        self.registrationToken = registrationToken
        self.appId = appId
        self.platform = platform
        self.deviceId = deviceId
        self.ssoId = ssoId
        self.packageName = packageName
    }
    
    enum CodingKeys: String, CodingKey {
        case isSubscriptionRequest = "isSubscriptionRequest"
        case registrationToken = "registrationToken"
        case appId = "appId"
        case platform = "platform"
        case deviceId = "deviceId"
        case ssoId = "ssoId"
        case packageName = "packageName"
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.isSubscriptionRequest, forKey: .isSubscriptionRequest)
        try container.encode(self.registrationToken, forKey: .registrationToken)
        try container.encode(self.appId, forKey: .appId)
        try container.encode(self.platform, forKey: .platform)
        try container.encode(self.deviceId, forKey: .deviceId)
        try container.encode(self.ssoId, forKey: .ssoId)
        try container.encode(self.packageName, forKey: .packageName)
    }
}
