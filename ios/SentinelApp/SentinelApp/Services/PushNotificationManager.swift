import SwiftUI
import UserNotifications

/// Manager for push notification registration
final class PushNotificationManager: NSObject, ObservableObject {
    @MainActor static let shared = PushNotificationManager()
    
    @MainActor @Published var isRegistered = false
    @MainActor @Published var deviceToken: String?
    
    private let baseURL = "http://192.168.29.252:8000/api/v1"
    
    private override init() {
        super.init()
    }
    
    /// Request notification permission and register for push
    func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("[Push] Permission granted")
            } else {
                print("[Push] Permission denied: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
    
    /// Handle successful device token registration
    @MainActor
    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        print("[Push] Device token: \(token)")
        
        // Register with backend
        Task {
            await registerWithBackend(token: token)
        }
    }
    
    /// Handle registration failure
    func handleRegistrationError(_ error: Error) {
        print("[Push] Registration failed: \(error.localizedDescription)")
    }
    
    /// Register device token with backend
    @MainActor
    private func registerWithBackend(token: String) async {
        guard let url = URL(string: "\(baseURL)/devices/register") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["token": token]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                isRegistered = true
                print("[Push] ✅ Registered with backend successfully")
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("[Push] Response: \(json)")
                }
            } else {
                print("[Push] ❌ Backend registration failed")
                if let httpResponse = response as? HTTPURLResponse {
                    print("[Push] Status Code: \(httpResponse.statusCode)")
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[Push] Body: \(responseString)")
                }
            }
        } catch {
            print("[Push] ❌ Backend registration error: \(error)")
        }
    }
    
    /// Unregister device
    @MainActor
    func unregister() async {
        guard let token = deviceToken else { return }
        guard let url = URL(string: "\(baseURL)/devices/unregister") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["token": token]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                isRegistered = false
                print("[Push] Unregistered from backend")
            }
        } catch {
            print("[Push] Unregistration error: \(error)")
        }
    }
}
