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
        decoder.dateDecodingStrategy = .iso8601
        
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
