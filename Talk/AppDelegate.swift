//
//  AppDelegate.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import UIKit
import TalkApp
import FirebaseCore
import FirebaseMessaging

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    override init() {
        super.init()
    }

    class var shared: AppDelegate! {
        UIApplication.shared.delegate as? AppDelegate
    }
    
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /// Notification setup
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        application.registerForRemoteNotifications()

        /// Firebase setup
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in}
        
        let forceLeitner = UserDefaults.standard.bool(forKey: SceneDelegate.L_FORCE)
        if forceLeitner { return true }
        ChatDelegateImplementation.sharedInstance.initialize()
        ChatDelegateImplementation.sharedInstance.registerOnConnect()
        return true
    }
    
    @MainActor
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        print("Call exportDeliveryMetricsToBigQuery() from AppDelegate")
        Messaging.serviceExtension().exportDeliveryMetricsToBigQuery(withMessageInfo: userInfo)
        return UIBackgroundFetchResult.newData
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("APNs token retrieved: \(token)")
        // With swizzling disabled you must set the APNs token here.
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        let dict: [String: Any] = Dictionary(
            uniqueKeysWithValues: userInfo.compactMap { key, value in
                guard let stringKey = key as? String else { return nil }
                return (stringKey, value)
            }
        )
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            let payload = try JSONDecoder.instance.decode(NotificationPayload.self, from: data)
            
            if payload.requestType == .reaction {
                /// reject showing a notification if it is a reaction notification for the time being.
                return []
            }
            
            if AppState.shared.isInForeground { return [] } 
            
            Messaging.messaging().appDidReceiveMessage(userInfo)
            
            // [START_EXCLUDE]
            // Print message ID.
            if let messageID = userInfo[gcmMessageIDKey] {
                print("Message ID: \(messageID)")
            }
            // [END_EXCLUDE]∫
            
            // Print full message.
            print(userInfo)
            
            // Change this to your preferred presentation option
            // Note: UNNotificationPresentationOptions.alert has been deprecated.
            if #available(iOS 14.0, *) {
                return [.list, .banner, .sound]
            } else {
                return [.alert, .sound]
            }
        } catch {
            print("Error in decoding and presenting the notification: ", error)
            return []
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let message = "did receive notification: \(response.notification.request.content)"
        print(message)
        
        let userInfo = response.notification.request.content.userInfo
        
        AppState.shared.objectsContainer.navVM.onTappedOnNotif(response: response)
        
        // [START_EXCLUDE]
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        // [END_EXCLUDE]
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print full message.
        print(userInfo)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        FirebaseManager.setFirebaseToken(token: fcmToken)
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
