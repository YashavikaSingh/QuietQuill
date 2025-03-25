import SwiftUI

struct ContentView: View {
    @State private var selectedDate: Date? = nil
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                CalendarView(onDaySelected: { date in
                    selectedDate = date
                })
                .navigationTitle("QuietQuill")
                .background(
                    NavigationLink(
                        destination: selectedDate != nil ? AnyView(NotesView(date: selectedDate!)) : AnyView(EmptyView()),
                        isActive: Binding(
                            get: { selectedDate != nil },
                            set: { isActive in
                                if !isActive {
                                    selectedDate = nil
                                }
                            }
                        )
                    ) {
                        EmptyView()
                    }
                )
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Calendar")
            }
            .tag(0)
            
            SentimentChartView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Sentiment")
                }
                .tag(1)
        }
    }
}

struct NotesView: View {
    let date: Date
    @State private var text: String = ""
    @State private var title: String = ""
    @State private var sentiment: String = "No sentiment analyzed yet"
    @State private var sentimentScore: Double = 0.0
    @State private var suggestion: String = "No suggestion generated yet"
    @FocusState private var isTextEditorFocused: Bool
    
    // Custom color palette
    let primaryColor = Color(hex: "3C6E71")
    let secondaryColor = Color(hex: "ECCC61")
    let backgroundColor = Color(hex: "FBF7F4")
    let accentColor = Color(hex: "A1683A")
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Sentiment Display at Top
                VStack {
                    Text("Sentiment: \(sentiment)")
                        .font(.headline)
                        .foregroundColor(primaryColor)
                        .padding()
                }
                .background(secondaryColor.opacity(0.2))
                
                // Main Content Scroll View
                ScrollView {
                    VStack(spacing: 15) {
                        // Title Field
                        TextField("Enter Title", text: $title)
                            .font(.title2)
                            .padding()
                            .background(backgroundColor)
                            .cornerRadius(10)
                            .onChange(of: title) { newText in
                                autoSaveTitle(title: newText)
                            }
                        
                        // Text Editor with Placeholder
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("Start writing your diary entry...")
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                            
                            TextEditor(text: $text)
                                .frame(minHeight: 200)
                                .padding()
                                .background(backgroundColor)
                                .cornerRadius(10)
                                .focused($isTextEditorFocused)
                                .onChange(of: text) { newText in
                                    autoSaveText(text: newText)
                                }
                        }
                        
                        // Analysis Buttons
                        HStack(spacing: 15) {
                            Button(action: generateSuggestion) {
                                Text("Get Suggestion")
                                    .padding()
                                    .background(primaryColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: analyzeSentiment) {
                                Text("Analyze Sentiment")
                                    .padding()
                                    .background(accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        
                        // Suggestion Section (Scrollable)
                        ScrollView {
                            VStack(alignment: .leading) {
                                Text("Suggestion")
                                    .font(.headline)
                                    .foregroundColor(primaryColor)
                                
                                Text(suggestion)
                                    .padding()
                                    .background(secondaryColor.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.height > 50 {
                                hideKeyboard()
                            }
                        }
                )
            }
            .navigationTitle(formattedDate())
            .background(backgroundColor)
            .onAppear {
                loadSavedData()
            }
        }
    }

    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }

    func autoSaveText(text: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("text_\(formattedDateForFile()).txt")
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Text auto-saved to \(fileURL)")
        } catch {
            print("Error auto-saving text: \(error.localizedDescription)")
        }
    }

    func autoSaveTitle(title: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("title_\(formattedDateForFile()).txt")
        
        do {
            try title.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Title auto-saved to \(fileURL)")
        } catch {
            print("Error auto-saving title: \(error.localizedDescription)")
        }
    }

    func loadSavedData() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Load saved title
        let titleURL = documentsDirectory.appendingPathComponent("title_\(formattedDateForFile()).txt")
        if let savedTitle = try? String(contentsOf: titleURL, encoding: .utf8) {
            title = savedTitle
        }
        
        // Load saved text
        let textURL = documentsDirectory.appendingPathComponent("text_\(formattedDateForFile()).txt")
        if let savedText = try? String(contentsOf: textURL, encoding: .utf8) {
            text = savedText
        }
    }

    func formattedDateForFile() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    struct SentimentResponse: Codable {
        let mood: String?
        let sentiment_score: Double?
    }

    func analyzeSentiment() {
        guard let url = URL(string: "https://f05f-2607-fb91-309a-64a-6c91-c9c4-f6ff-e54.ngrok-free.app/analyze_sentiment/") else {
            print("Invalid URL")
            return
        }

        let requestBody: [String: String] = ["note": text]
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

            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }

            if let result = try? JSONDecoder().decode(SentimentResponse.self, from: data) {
                DispatchQueue.main.async {
                    sentiment = result.mood ?? "not working"
                    sentimentScore = result.sentiment_score ?? 0.0
                    
                    // Save sentiment score
                    saveSentimentScore(sentimentScore)
                    
                    print("Sentiment score: \(result.sentiment_score)")
                }
            } else {
                print("Failed to decode response")
            }
        }.resume()
    }
    
    // Method to save sentiment score
    private func saveSentimentScore(_ score: Double) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("sentiment_\(formattedDateForFile()).txt")
        
        do {
            try String(score).write(to: fileURL, atomically: true, encoding: .utf8)
            print("Sentiment score saved to \(fileURL)")
        } catch {
            print("Error saving sentiment score: \(error.localizedDescription)")
        }
    }
    
    struct SuggestionResponse: Codable {
        let suggestion: String
    }

    func generateSuggestion() {
        guard let url = URL(string: "https://f05f-2607-fb91-309a-64a-6c91-c9c4-f6ff-e54.ngrok-free.app/generate") else {
            print("Invalid URL")
            return
        }

        let requestBody: [String: String] = ["text": text]
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

            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }

            if let result = try? JSONDecoder().decode(SuggestionResponse.self, from: data) {
                DispatchQueue.main.async {
                    suggestion = result.suggestion
                    print("Generated Suggestion: \(result.suggestion)")
                }
            } else {
                print("Failed to decode response")
            }
        }.resume()
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
  ContentView()
}