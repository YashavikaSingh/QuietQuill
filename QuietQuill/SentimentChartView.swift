import SwiftUI
import Charts

struct MonthlySummaryView: View {
    let month: String
    @State private var monthlySummary: String = ""
    
    // Custom color palette
    let primaryColor = Color(hex: "3C6E71")
    let secondaryColor = Color(hex: "ECCC61")
    let backgroundColor = Color(hex: "FBF7F4")
    let accentColor = Color(hex: "A1683A")
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Monthly Summary: \(month)")
                    .font(.title2)
                    .foregroundColor(primaryColor)
                    .padding()
                
                Text(monthlySummary)
                    .padding()
                    .background(backgroundColor)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            fetchMonthlySummary()
        }
    }
    
    func fetchMonthlySummary() {
        guard let url = URL(string: "https://f05f-2607-fb91-309a-64a-6c91-c9c4-f6ff-e54.ngrok-free.app/monthly_summary") else {
            print("Invalid URL")
            return
        }
        
        let diaryEntries = loadDiaryEntriesForMonth(month)
        
        let requestBody: [String: Any] = [
            "month": month,
            "entries": diaryEntries
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize JSON")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            if let result = try? JSONDecoder().decode(SummaryResponse.self, from: data) {
                DispatchQueue.main.async {
                    monthlySummary = result.summary
                }
            } else {
                print("Failed to decode response")
            }
        }.resume()
    }
    
    func loadDiaryEntriesForMonth(_ month: String) -> [String] {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var monthEntries: [String] = []
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            
            let textFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix("text_") }
            
            for fileURL in textFiles {
                let filename = fileURL.lastPathComponent
                let dateString = filename.replacingOccurrences(of: "text_", with: "").replacingOccurrences(of: ".txt", with: "")
                
                if let date = dateFormatter.date(from: dateString) {
                    let monthFormatter = DateFormatter()
                    monthFormatter.dateFormat = "MMMM yyyy"
                    let monthKey = monthFormatter.string(from: date)
                    
                    if monthKey == month {
                        let entry = try String(contentsOf: fileURL, encoding: .utf8)
                        monthEntries.append(entry)
                    }
                }
            }
        } catch {
            print("Error loading entries: \(error)")
        }
        
        return monthEntries
    }
}

struct SummaryResponse: Codable {
    let summary: String
}

struct MonthlySentiment: Identifiable {
    let id = UUID()
    let month: String
    let sentimentScore: Double
}

// ✅ Wrapper struct to make String Identifiable
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

struct SentimentChartView: View {
    @State private var sentimentData: [MonthlySentiment] = []
    @State private var selectedMonth: IdentifiableString?
    
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
                Button(action: {
                    selectedMonth = IdentifiableString(value: entry.month)
                }) {
                    HStack {
                        Text(entry.month)
                        Spacer()
                        Text(String(format: "%.2f", entry.sentimentScore))
                            .foregroundColor(entry.sentimentScore > 0 ? primaryColor : accentColor)
                    }
                }
            }
        }
        .background(backgroundColor)
        .sheet(item: $selectedMonth) { month in
            MonthlySummaryView(month: month.value)
        }
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

#Preview {
    SentimentChartView()
}