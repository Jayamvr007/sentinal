import SwiftUI

/// View for managing price alerts
struct AlertsView: View {
    @StateObject private var alertService = AlertService.shared
    
    // Form state
    @State private var selectedSymbol = "AAPL"
    @State private var selectedCondition = "below"
    @State private var targetPriceText = ""
    @State private var isCreating = false
    
    // Alert triggered popup
    @State private var showTriggeredAlert = false
    @State private var triggeredAlertMessage = ""
    
    private let symbols = ["AAPL", "GOOGL", "TSLA", "MSFT", "AMZN", "NVDA", "META", "JPM", "V", "SPY"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Create Alert Form
                    createAlertForm
                    
                    // Alerts List
                    alertsList
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Alerts")
            .task {
                await alertService.fetchAlerts()
            }
            .refreshable {
                await alertService.fetchAlerts()
            }
            .onReceive(NotificationCenter.default.publisher(for: .alertTriggered)) { notification in
                // Refresh alerts when one is triggered
                Task {
                    await alertService.fetchAlerts()
                }
                // Show triggered alert popup
                if let data = notification.userInfo?["data"] as? [String: Any],
                   let symbol = data["symbol"] as? String,
                   let condition = data["condition"] as? String,
                   let targetPrice = data["target_price"] as? Double {
                    triggeredAlertMessage = "\(symbol) went \(condition) $\(String(format: "%.2f", targetPrice))"
                    showTriggeredAlert = true
                }
            }
            .alert("🎯 Alert Triggered!", isPresented: $showTriggeredAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(triggeredAlertMessage)
            }
        }
    }
    
    // MARK: - Create Alert Form
    
    private var createAlertForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Alert")
                .font(.headline)
                .foregroundStyle(.white)
            
            HStack(spacing: 12) {
                // Symbol Picker
                Menu {
                    ForEach(symbols, id: \.self) { symbol in
                        Button(symbol) { selectedSymbol = symbol }
                    }
                } label: {
                    HStack {
                        Text(selectedSymbol)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Condition Picker
                Menu {
                    Button("Price Below") { selectedCondition = "below" }
                    Button("Price Above") { selectedCondition = "above" }
                } label: {
                    HStack {
                        Text(selectedCondition == "below" ? "↘ Below" : "↗ Above")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Price Input
                TextField("Target Price", text: $targetPriceText)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                
                // Create Button
                Button {
                    Task { await createAlert() }
                } label: {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "plus.circle.fill")
                            Text("Create")
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(targetPriceText.isEmpty || isCreating)
                .opacity(targetPriceText.isEmpty ? 0.5 : 1)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Alerts List
    
    private var alertsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Alerts")
                .font(.headline)
                .foregroundStyle(.white)
            
            if alertService.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if alertService.alerts.isEmpty {
                emptyState
            } else {
                ForEach(alertService.alerts) { alert in
                    alertRow(alert)
                }
            }
            
        }
    }
    
    @State private var debugMessage = ""
    @State private var debugIsError = false
    
    private func checkConnection() {
        Task {
            debugMessage = "Checking connection..."
            debugIsError = false
            do {
                let url = URL(string: "http://192.168.29.252:8000/")!
                let (_, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    debugMessage = "✅ Connected to backend!"
                    debugIsError = false
                } else {
                    debugMessage = "❌ Server returned error"
                    debugIsError = true
                }
            } catch {
                debugMessage = "❌ Error: \(error.localizedDescription)"
                debugIsError = true
            }
        }
    }
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 40))
                .foregroundStyle(.gray)
            Text("No alerts yet")
                .font(.headline)
                .foregroundStyle(.gray)
            Text("Create an alert to get notified when prices change")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.ultraThinMaterial.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func alertRow(_ alert: Alert) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.symbol)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("\(alert.conditionText) $\(alert.targetPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            // Status Badge
            if alert.isTriggered {
                Text("✓ Triggered")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            } else {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.2))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            
            // Delete Button
            Button {
                Task { await deleteAlert(alert.id) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Actions
    
    private func createAlert() async {
        guard let price = Double(targetPriceText) else { return }
        
        isCreating = true
        let success = await alertService.createAlert(
            symbol: selectedSymbol,
            condition: selectedCondition,
            targetPrice: price
        )
        isCreating = false
        
        if success {
            targetPriceText = ""
        }
    }
    
    private func deleteAlert(_ id: String) async {
        _ = await alertService.deleteAlert(id: id)
    }
}

#Preview {
    AlertsView()
        .preferredColorScheme(.dark)
}
