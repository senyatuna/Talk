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
    private static let FIREBASE_REGISTERATION_TOKEN_KEY = "FIREBASE_REGISTERATION_TOKEN_KEY"
    private static let TOKEN_SYNCED_KEY = "TOKEN_SYNCED_KEY"
    
    /// Subscription API paramters
    private let APP_ID = "1bec808b-4e60-47bd-8f3f-8f000478aca4"
    private let SANDBOX_APP_ID = "1bec808b-4e60-47bd-8f3f-8f000478aca4"
    private let packageName = "com.lmlvrmedia.leitnerbox"
    private var accessToken: String = ""
    private var firebaseToken: String = ""
    private var deviceId: String = ""
    private var ssoId: Int = -1

    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func subscribe() async {
        guard
            FirebaseManager.isTokenSynced() == false
        else { return }
        await setParameters()
        /// We move to another Task to unblock current Task and on logged in immediately
        Task {
            await doSubscribtion(subscribe: true)
        }
    }
    
    public func unsubscribe() async {
        await setParameters()
        /// We move to another Task to unblock current Task and logout immediately
        Task {
            await doSubscribtion(subscribe: false)
        }
    }
    
    private func doSubscribtion(subscribe: Bool) async {
        log("Trying to \(subscribe ? "subscribe to" : "unsusbscrie from") the notification server with a firebase token: \(firebaseToken)")
        do {
            let urlReq = try makeRegistrationRequest(subscribe: subscribe)
            let (data, resp) = try await session.data(for: urlReq)
            if let httpResponse = resp as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let decodedResponse = try JSONDecoder.instance.decode(NotificationRegisterResponse.self, from: data)
                FirebaseManager.setTokenSynced(value: subscribe)
                log("Successfully \(subscribe ? "sbuscribed" : "unsubscribed") with ssoId: \(ssoId)")
            } else {
                let stringBody = String(data: data, encoding: .utf8)
                log("Failed to \(subscribe ? "subscribe" : "unsubscribe") with ssoId: \(ssoId) stringBody: \(stringBody)")
            }
            let log = Logger.makeLog(prefix: "TALK_REGISTER_TOKEN:", request: urlReq, response: (data, resp))
            self.log(log)
        } catch {
            log("Error on \(subscribe ? "subscribing to" : "unsubscribing from") the notification server with error: \(error.localizedDescription)")
        }
    }
    
    private func makeRegistrationRequest(subscribe: Bool) throws -> URLRequest {
        let spec = AppState.shared.spec
        let isSandbox = SpecManagerViewModel.shared.isSandbox()
        let address = isSandbox ? Constants.subsribeNotificationSandbox.fromBase64() ?? "" : Constants.subsribeNotificationMain.fromBase64() ?? ""
        let clientId = spec.paths.sso.clientId
        let req = NotificationRegisterationRequest(
            isSubscriptionRequest: subscribe,
            registrationToken: firebaseToken,
            appId: isSandbox ? SANDBOX_APP_ID : APP_ID,
            deviceId: deviceId,
            ssoId: ssoId,
            packageName: packageName)
        guard let url = URL(string: address)
        else { throw URLError(.badURL) }
        var urlReq = URLRequest(url: url)
        urlReq.httpMethod = "POST"
        urlReq.httpBody = try JSONEncoder.instance.encode(req)
        urlReq.allHTTPHeaderFields = ["content-type": "application/json", "apiToken": accessToken]
        return urlReq
    }
    
    public static func isTokenSynced() -> Bool {
        return UserDefaults.standard.bool(forKey: TOKEN_SYNCED_KEY)
    }
    
    public static func setTokenSynced(value: Bool) {
        return UserDefaults.standard.set(value, forKey: TOKEN_SYNCED_KEY)
    }

    public static func getFirebaseToken() -> String? {
        return UserDefaults.standard.string(forKey: FIREBASE_REGISTERATION_TOKEN_KEY)
    }

    public static func setFirebaseToken(token: String?) {
        if let token = token {
            UserDefaults.standard.set(token, forKey: FIREBASE_REGISTERATION_TOKEN_KEY)
        } else {
            UserDefaults.standard.removeObject(forKey: FIREBASE_REGISTERATION_TOKEN_KEY)
        }
        log("Firebase token is: \(token ?? "")")
    }
    
    private func setParameters() async {
        guard
            let ssoToken = await TokenManager.shared.getSSOTokenFromUserDefaultsAsync(),
            let firebaseToken = FirebaseManager.getFirebaseToken(),
            let ssoIdString = AppState.shared.user?.ssoId,
            let deviceId = await FirebaseManager.getAsyncConfig(),
            let ssoId = Int(ssoIdString)
        else { return }
        
        self.accessToken = ssoToken.accessToken ?? ""
        self.firebaseToken = firebaseToken
        self.deviceId = deviceId
        self.ssoId = ssoId
    }
    
    @ChatGlobalActor
    private static func getAsyncConfig() -> String? {
        ChatManager.activeInstance?.config.asyncConfig.deviceId
    }
    
    private static func log(_ message: String) {
        Logger.log(title: "FirebaseManager", message: message)
    }
    
    private func log(_ message: String) {
        FirebaseManager.log(message)
    }
}
