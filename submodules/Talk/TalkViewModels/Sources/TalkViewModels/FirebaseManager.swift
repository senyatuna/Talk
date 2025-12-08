//
//  FirebaseManager.swift
//  TalkViewModels
//
//  Created by hamed on 3/16/23.
//

import Chat
import Foundation
import Logger
import TalkExtensions
import TalkModels

@MainActor
public final class FirebaseManager: ObservableObject {
    public let session: URLSession
    public static let shared = FirebaseManager()
    public static let FIREBASE_REGISTERATION_TOKEN = "FIREBASE_REGISTERATION_TOKEN"
    public static let NOTIFICATION_REGISTRATION_RESULT = "NOTIFICATION_REGISTRAION_RESULT"

    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func register() async {
        guard
            FirebaseManager.getNotificationRegistrationResult() == false,
            let ssoToken = await TokenManager.shared.getSSOTokenFromUserDefaultsAsync(),
            let firebaseToken = FirebaseManager.getFirebaseToken(),
            let ssoIdString = AppState.shared.user?.ssoId,
            let deviceId = await getAsyncConfig(),
            let ssoId = Int(ssoIdString)
        else { return }
        
        do {
            let urlReq = try makeRegistrationRequest(apiToken: ssoToken.accessToken ?? "",
                                                     firebaseToken: firebaseToken,
                                                     appId: "PodChat",
                                                     deviceId: deviceId,
                                                     ssoId: ssoId)
            let resp = try await session.data(for: urlReq)
            FirebaseManager.setNotificationRegistrationResult(value: true)
            let log = Logger.makeLog(prefix: "TALK_REGISTER_TOKEN:", request: urlReq, response: resp)
            self.log(log)
        } catch {
            log("Error on registering firebase token wiht the notification server")
        }
    }
    
    @ChatGlobalActor
    private func getAsyncConfig() -> String? {
        ChatManager.activeInstance?.config.asyncConfig.deviceId
    }
    
    private func makeRegistrationRequest(apiToken: String,
                                         firebaseToken: String,
                                         appId: String,
                                         deviceId: String,
                                         ssoId: Int)
        throws -> URLRequest
    {
        let spec = AppState.shared.spec
        /// Sandbox
         let address = "https://api.sandpod.ir/srv/notif-sandbox/push/device/subscribe"
        
        /// Production
//        let address = "https://api.pod.ir/srv/notification/push/device/subscribe"
        
        let clientId = spec.paths.sso.clientId
        let req = NotificationRegisterationRequest(
            registrationToken: firebaseToken,
            appId: appId,
            deviceId: deviceId,
            ssoId: ssoId,
            packageName: "com.lmlvrmedia.leitnerbox")
        guard let url = URL(string: address)
        else { throw URLError(.badURL) }
        var urlReq = URLRequest(url: url)
        urlReq.httpMethod = "POST"
        urlReq.httpBody = try JSONEncoder.instance.encode(req)
        urlReq.allHTTPHeaderFields = ["content-type": "application/json", "apiToken": apiToken]
        return urlReq
    }
    
    public static func getNotificationRegistrationResult() -> Bool {
        return UserDefaults.standard.bool(forKey: NOTIFICATION_REGISTRATION_RESULT) == true
    }
    
    public static func setNotificationRegistrationResult(value: Bool) {
        return UserDefaults.standard.set(value, forKey: NOTIFICATION_REGISTRATION_RESULT)
    }

    public static func getFirebaseToken() -> String? {
        return UserDefaults.standard.string(forKey: FIREBASE_REGISTERATION_TOKEN)
    }

    public static func setFirebaseToken(token: String?) {
        if let token = token {
            UserDefaults.standard.set(
                token, forKey: FIREBASE_REGISTERATION_TOKEN)
        } else {
            UserDefaults.standard.removeObject(
                forKey: FIREBASE_REGISTERATION_TOKEN)
        }
    }

    private func log(_ message: String) {
        Logger.log(title: "FirebaseManager", message: message)
    }

    public struct NotificationRegisterationRequest: Codable {
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
    }
}
