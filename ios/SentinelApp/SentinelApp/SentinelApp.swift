import SwiftUI
import UserNotifications

/// App Delegate to handle push notification registration
class AppDelegate: NSObject, UIApplicationDelegate {
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationManager.shared.handleDeviceToken(deviceToken)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushNotificationManager.shared.handleRegistrationError(error)
        }
    }
}

// Handle foreground notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is invalid
        completionHandler([.banner, .sound, .badge])
    }
}

/// Main app entry point
@main
struct SentinelApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Request push notification permission on app launch
                    PushNotificationManager.shared.requestPermissionAndRegister()
                }
        }
    }
}
