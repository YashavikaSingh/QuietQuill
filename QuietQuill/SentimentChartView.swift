import SwiftUI
import Charts

struct SentimentChartView: View {
    @State private var sentimentData: [MonthlySentiment] = []
    
    // Custom color palette
    let primaryColor = Color(hex: "3C6E71")
    let secondaryColor = Color(hex: "ECCC61")
    let backgroundColor = Color(hex: "FBF7F4")
    let accentColor = Color(hex: "A1683A")
    
    var body: some View {
        VStack {
            Text("Monthly Sentiment Overview")
                .font(.title2)
                .foregroundColor(primaryColor)
                .padding()
            
            Chart {
                ForEach(sentimentData) { entry in
                    BarMark(
                        x: .value("Month", entry.month),
                        y: .value("Sentiment Score", entry.sentimentScore)
                    )
                    .foregroundStyle(
                        entry.sentimentScore > 0 ? 
                        primaryColor.gradient : 
                        accentColor.gradient
                    )
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 300)
            .padding()
            
            List(sentimentData) { entry in
                HStack {
                    Text(entry.month)
                    Spacer()
                    Text(String(format: "%.2f", entry.sentimentScore))
                        .foregroundColor(entry.sentimentScore > 0 ? primaryColor : accentColor)
                }
            }
        }
        .background(backgroundColor)
        .onAppear {
            loadSentimentData()
        }
    }
    
    func loadSentimentData() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var monthSentiments: [String: [Double]] = [:]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            
            let sentimentFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix("sentiment_") }
            
            for fileURL in sentimentFiles {
                let content = try String(contentsOf: fileURL)
                if let score = Double(content) {
                    let filename = fileURL.lastPathComponent
                    let dateString = filename.replacingOccurrences(of: "sentiment_", with: "").replacingOccurrences(of: ".txt", with: "")
                    
                    if let date = dateFormatter.date(from: dateString) {
                        let monthFormatter = DateFormatter()
                        monthFormatter.dateFormat = "MMMM yyyy"
                        let monthKey = monthFormatter.string(from: date)
                        
                        monthSentiments[monthKey, default: []].append(score)
                    }
                }
            }
            
            // Calculate average sentiment for each month
            sentimentData = monthSentiments.map { (month, scores) in
                MonthlySentiment(
                    month: month, 
                    sentimentScore: scores.reduce(0, +) / Double(scores.count)
                )
            }.sorted { $0.month < $1.month }
            
        } catch {
            print("Error loading sentiment data: \(error)")
        }
    }
}

// Data model for monthly sentiment
struct MonthlySentiment: Identifiable {
    let id = UUID()
    let month: String
    let sentimentScore: Double
}