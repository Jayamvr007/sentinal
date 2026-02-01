import SwiftUI
import Charts

/// Chart data point for visualization
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
    let type: DataType
    
    enum DataType: String {
        case historical = "Historical"
        case predicted = "Predicted"
    }
}

/// Interactive prediction chart using Swift Charts
struct PredictionChartView: View {
    let historicalPrices: [HistoricalPrice]
    let predictions: [Prediction]
    let currentPrice: Double
    
    @State private var selectedPoint: ChartDataPoint?
    
    private var chartData: [ChartDataPoint] {
        var data: [ChartDataPoint] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        // Historical prices
        for hp in historicalPrices {
            if let date = dateFormatter.date(from: hp.date) {
                data.append(ChartDataPoint(date: date, price: hp.price, type: .historical))
            }
        }
        
        // Predictions
        for pred in predictions {
            if let date = dateFormatter.date(from: pred.date) {
                data.append(ChartDataPoint(date: date, price: pred.predicted_price, type: .predicted))
            }
        }
        
        return data.sorted { $0.date < $1.date }
    }
    
    private var historicalData: [ChartDataPoint] {
        chartData.filter { $0.type == .historical }
    }
    
    private var predictedData: [ChartDataPoint] {
        chartData.filter { $0.type == .predicted }
    }
    
    private var priceRange: ClosedRange<Double> {
        let prices = chartData.map { $0.price }
        let minPrice = (prices.min() ?? 0) * 0.98
        let maxPrice = (prices.max() ?? 100) * 1.02
        return minPrice...maxPrice
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("📊 Price Trend & Forecast")
                    .font(.headline)
                
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    legendItem(color: .blue, text: "Historical")
                    legendItem(color: .purple, text: "Predicted")
                }
                .font(.caption)
            }
            
            // Selected Point Info
            if let point = selectedPoint {
                HStack {
                    Text(point.date, format: .dateTime.month().day())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("₹\(point.price, specifier: "%.2f")")
                        .fontWeight(.semibold)
                        .foregroundStyle(point.type == .predicted ? .purple : .blue)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Chart
            Chart {
                // Historical line
                ForEach(historicalData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Predicted line
                ForEach(predictedData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(.purple)
                    .symbolSize(30)
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .purple.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Current price reference line
                RuleMark(y: .value("Current", currentPrice))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("₹\(currentPrice, specifier: "%.0f")")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
            }
            .chartYScale(domain: priceRange)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text("₹\(price, specifier: "%.0f")")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                    if let date: Date = proxy.value(atX: x) {
                                        // Find closest point
                                        selectedPoint = chartData.min(by: {
                                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                        })
                                    }
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
            .frame(height: 220)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}

/// Historical price data point from API
struct HistoricalPrice: Codable {
    let date: String
    let price: Double
}

/// Trend summary from API
struct TrendSummary: Codable {
    let direction: String
    let change_percent: Double
    let days: Int
    
    var isPositive: Bool {
        direction == "bullish"
    }
}
