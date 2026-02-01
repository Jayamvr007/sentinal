import Foundation

/// Service for fetching AI predictions from backend
@MainActor
class PredictionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var prediction: PredictionResponse?
    @Published var availableSymbols: [String] = []
    @Published var error: String?
    
    // MARK: - Configuration
    private let baseURL = "http://192.168.29.252:8000/api/v1/prediction"
    
    // MARK: - Public Methods
    
    /// Fetch available NIFTY 50 symbols
    func fetchSymbols() async {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(baseURL)/symbols/top") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                error = "Server error"
                isLoading = false
                return
            }
            
            let decoded = try JSONDecoder().decode(SymbolListResponse.self, from: data)
            availableSymbols = decoded.symbols
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Fetch prediction for a specific symbol
    func fetchPrediction(for symbol: String, days: Int = 7) async {
        isLoading = true
        error = nil
        prediction = nil
        
        // Remove .NS suffix for API call (API adds it automatically)
        let cleanSymbol = symbol.replacingOccurrences(of: ".NS", with: "")
        
        guard let url = URL(string: "\(baseURL)/\(cleanSymbol)?days=\(days)") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                error = "Invalid response"
                isLoading = false
                return
            }
            
            if httpResponse.statusCode == 200 {
                prediction = try JSONDecoder().decode(PredictionResponse.self, from: data)
            } else if httpResponse.statusCode == 400 {
                // Parse error from response
                if let errorDict = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorDict["detail"] {
                    error = detail
                } else {
                    error = "Failed to get prediction"
                }
            } else {
                error = "Server error: \(httpResponse.statusCode)"
            }
            
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Clear current prediction
    func clearPrediction() {
        prediction = nil
        error = nil
    }
}
