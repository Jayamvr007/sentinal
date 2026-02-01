import SwiftUI
import Charts

/// AI Prediction View for NIFTY 50 stocks
struct PredictionView: View {
    @StateObject private var service = PredictionService()
    @State private var selectedSymbol: String = "RELIANCE"
    @State private var selectedDays: Int = 7
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Symbol Picker
                    symbolPickerSection
                    
                    // Loading / Error / Content
                    if service.isLoading {
                        loadingView
                    } else if let error = service.error {
                        errorView(error)
                    } else if let prediction = service.prediction {
                        predictionContent(prediction)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("AI Insights")
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color.purple.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .task {
                await service.fetchSymbols()
            }
        }
    }
    
    // MARK: - Symbol Picker
    private var symbolPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Stock")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if service.availableSymbols.isEmpty {
                // Fallback picker with common symbols
                Picker("Symbol", selection: $selectedSymbol) {
                    ForEach(defaultSymbols, id: \.self) { symbol in
                        Text(symbol.replacingOccurrences(of: ".NS", with: ""))
                            .tag(symbol.replacingOccurrences(of: ".NS", with: ""))
                    }
                }
                .pickerStyle(.segmented)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(service.availableSymbols, id: \.self) { symbol in
                            let cleanSymbol = symbol.replacingOccurrences(of: ".NS", with: "")
                            Button {
                                selectedSymbol = cleanSymbol
                            } label: {
                                Text(cleanSymbol)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedSymbol == cleanSymbol
                                        ? Color.purple
                                        : Color(.systemGray5)
                                    )
                                    .foregroundStyle(
                                        selectedSymbol == cleanSymbol
                                        ? .white
                                        : .primary
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            Button {
                Task {
                    await service.fetchPrediction(for: selectedSymbol, days: selectedDays)
                }
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Get AI Prediction")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.gradient)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Prediction Content
    @ViewBuilder
    private func predictionContent(_ prediction: PredictionResponse) -> some View {
        // Current Price Card with Trend Badge
        currentPriceCard(prediction)
        
        // Trend Summary Badge
        if let trend = prediction.trend_summary {
            trendSummaryBadge(trend)
        }
        
        // Chart Visualization
        if let historicalPrices = prediction.historical_prices, !historicalPrices.isEmpty {
            PredictionChartView(
                historicalPrices: historicalPrices,
                predictions: prediction.predictions,
                currentPrice: prediction.current_price
            )
        }
        
        // Predictions List
        predictionsListCard(prediction)
        
        // Disclaimer
        disclaimerCard(prediction.disclaimer)
    }
    
    private func trendSummaryBadge(_ trend: TrendSummary) -> some View {
        HStack(spacing: 8) {
            Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.subheadline)
            Text(trend.isPositive ? "Bullish" : "Bearish")
                .fontWeight(.medium)
            Text("(\(trend.change_percent >= 0 ? "+" : "")\(String(format: "%.1f", trend.change_percent))% in \(trend.days) days)")
                .font(.subheadline)
                .opacity(0.8)
        }
        .foregroundStyle(trend.isPositive ? .green : .red)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(trend.isPositive ? .green.opacity(0.1) : .red.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private func currentPriceCard(_ prediction: PredictionResponse) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.symbol.replacingOccurrences(of: ".NS", with: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Current Price")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(prediction.formattedCurrentPrice)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: prediction.isPositive ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text(prediction.formattedChangePercent)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(prediction.isPositive ? .green : .red)
                }
            }
            
            HStack {
                Label("\(prediction.model_type) Model", systemImage: "brain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label("\(prediction.lookback_days) day lookback", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func predictionsListCard(_ prediction: PredictionResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(selectedDays)-Day Forecast")
                    .font(.headline)
                
                Spacer()
                
                // Days Toggle
                Picker("Days", selection: $selectedDays) {
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .onChange(of: selectedDays) { oldValue, newValue in
                    Task {
                        await service.fetchPrediction(for: selectedSymbol, days: newValue)
                    }
                }
            }
            
            ForEach(prediction.predictions) { pred in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDate(pred.date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                            Text("\(Int(pred.confidence * 100))% confidence")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(pred.formattedPrice)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(pred.formattedChange)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(pred.isPositive ? .green : .red)
                    }
                }
                .padding(.vertical, 8)
                
                if pred.id != prediction.predictions.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func disclaimerCard(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Views
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing market data...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("First prediction may take 30-60 seconds")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            
            Text("Prediction Failed")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await service.fetchPrediction(for: selectedSymbol)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundStyle(.purple.opacity(0.6))
            
            Text("AI-Powered Predictions")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Select a stock and tap 'Get AI Prediction' to see our LSTM model's forecast for the next 7 days.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helpers
    private var defaultSymbols: [String] {
        ["RELIANCE.NS", "TCS.NS", "HDFCBANK.NS", "INFY.NS", "ICICIBANK.NS"]
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEE, MMM d"
        outputFormatter.locale = Locale.current
        outputFormatter.timeZone = TimeZone.current
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    PredictionView()
}
