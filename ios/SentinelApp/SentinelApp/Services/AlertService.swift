import Foundation

/// Service for managing alerts via the REST API
@MainActor
final class AlertService: ObservableObject {
    static let shared = AlertService()
    
    @Published var alerts: [Alert] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL = "http://192.168.29.252:8000/api/v1"
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        decoder = JSONDecoder()
        // Custom date decoder to handle dates without timezone from backend
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        // Also support dates with timezone
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try the basic format first (from backend)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            // Try ISO8601 with timezone
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    /// Fetch all alerts from the server
    func fetchAlerts() async {
        isLoading = true
        error = nil
        
        do {
            guard let url = URL(string: "\(baseURL)/alerts") else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            alerts = try decoder.decode([Alert].self, from: data)
        } catch {
            self.error = error.localizedDescription
            print("[AlertService] Fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Create a new alert
    func createAlert(symbol: String, condition: String, targetPrice: Double) async -> Bool {
        guard let url = URL(string: "\(baseURL)/alerts") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let alertData = AlertCreate(symbol: symbol, condition: condition, targetPrice: targetPrice)
        
        do {
            request.httpBody = try encoder.encode(alertData)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201 else {
                return false
            }
            
            let newAlert = try decoder.decode(Alert.self, from: data)
            alerts.insert(newAlert, at: 0)
            return true
        } catch {
            self.error = error.localizedDescription
            print("[AlertService] Create error: \(error)")
            return false
        }
    }
    
    /// Delete an alert by ID
    func deleteAlert(id: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/alerts/\(id)") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            alerts.removeAll { $0.id == id }
            return true
        } catch {
            self.error = error.localizedDescription
            print("[AlertService] Delete error: \(error)")
            return false
        }
    }
}
