import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase BEFORE anything else
    FirebaseApp.configure()
    
    // Set delegates BEFORE registering for notifications
    Messaging.messaging().delegate = self
    
    // Configure UNUserNotificationCenter
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("📱 Notification permission granted: \(granted)")
          if let error = error {
            print("❌ Notification permission error: \(error)")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    
    // Configure Firebase Messaging for foreground presentation
    Messaging.messaging().isAutoInitEnabled = true
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // CRITICAL: Handle APNS token registration for iOS
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("📱 APNS token received successfully")
    // Map APNS token to FCM registration token
    Messaging.messaging().apnsToken = deviceToken
    
    // Log token for debugging
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("📱 APNS token: \(token.prefix(20))...")
  }
  
  // Handle APNS token registration failure
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error)")
  }
  
  // CRITICAL: Handle notification when app is in foreground (iOS 10+)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("🔔 Foreground notification received: \(userInfo)")
    
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  // CRITICAL: Handle notification tap for deep-linking
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("👆 Notification tapped: \(userInfo)")
    
    // Handle deep-linking data
    if let type = userInfo["type"] as? String,
       let symbol = userInfo["symbol"] as? String,
       let timeframe = userInfo["target_timeframe"] as? String ?? userInfo["timeframe"] as? String {
      print("🧭 Deep-link navigation: \(type) -> \(symbol) (\(timeframe))")
    }
    
    completionHandler()
  }
  
  // Handle app launch from terminated state via notification
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("📱 Remote notification received in background/terminated: \(userInfo)")
    
    // Process the notification data
    if let type = userInfo["type"] as? String, type == "trading_tip" {
      print("📈 Trading tip notification in background")
      completionHandler(.newData)
    } else {
      completionHandler(.noData)
    }
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  // CRITICAL: Handle FCM token refresh
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔑 FCM registration token: \(fcmToken ?? "nil")")
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    
    // TODO: Send token to your application server for targeting notifications
  }
}
