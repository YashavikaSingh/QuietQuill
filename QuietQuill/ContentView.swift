//
//  ContentView.swift
//  QuietQuill
//
//  Created by Yashavika Singh on 16.01.25.
//




import SwiftUI



struct ContentView: View {
    @State private var selectedDate: Date? = nil

    var body: some View {
        NavigationView {
            CalendarView(onDaySelected: { date in
                selectedDate = date
            })
            .navigationTitle("Calendar")
            .background(
                NavigationLink(
                    destination: selectedDate != nil ? AnyView(NotesView(date: selectedDate!)) : AnyView(EmptyView()), // Use AnyView to wrap both
                    isActive: Binding(
                        get: { selectedDate != nil },
                        set: { isActive in
                            if !isActive {
                                selectedDate = nil
                            }
                        }
                    )
                ) {
                    EmptyView() // Hidden NavigationLink trigger
                }
            )
        }
    }
}


struct NotesView: View {
    let date : Date
    @State private var text: String = ""
    @State private var title: String = ""
    @State private var sentiment: String = "No sentiment analyzed yet"
    @State private var suggestion: String = "No suggestion generated yet"
    @State private var currentDate = Date()
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView{
                VStack {
                    
                    TextEditor(text: $title)
                        .frame(height: 50)
                        .onChange(of: title) { newText in
                            // Auto-save whenever the text changes
                            autoSaveTitle(title: newText)
                        }// Set height to 0 to prevent it from taking up space
                    
                    TextEditor(text: $text)
                        .padding()
                        .focused($isTextEditorFocused)
                        .onChange(of: text) { newText in
                            // Auto-save whenever the text changes
                            autoSaveText(text: newText)
                        }
                    
                    
                    Spacer()
                    HStack{
                        
                        
                        VStack{
                            Button(action: generateSuggestion) {
                                Text("Create Suggestion")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding()
                            
                            
                            
                            Text("Suggestion: \(suggestion)")
                                .padding()
                                .font(.headline)
                        }
                        
                        VStack{
                            Button(action: analyzeSentiment) {
                                Text("Analyze Sentiment")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding()
                            Text("Sentiment: \(sentiment)")
                                .padding()
                                .font(.headline)
                        }
                        
                    }
                    
                }
                
            }
            .toolbar {
                       // Add the "Done" button to the toolbar
                       ToolbarItemGroup(placement: .keyboard) {
                           Button("Done") {
                               hideKeyboard() // Dismiss keyboard when the "Done" button is pressed
                           }
                       }
                   }
            .navigationTitle(Text(formattedDate()))
            .padding()
            .onAppear {
                // Load saved title and text when the view appears
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
        dateFormatter.dateFormat = "yyyy-MM-dd" // Use a simple date format suitable for filenames
        return dateFormatter.string(from: date)
    }

    
    
    struct SentimentResponse: Codable {
        let mood: String?
        let sentiment_score: Double?
    }

    func analyzeSentiment() {
        // Backend URL
        guard let url = URL(string: "https://bbcf-122-161-65-27.ngrok-free.app/analyze_sentiment/") else {
            print("Invalid URL")
            return
        }

        // Create JSON data
        let requestBody: [String: String] = ["note": text]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize JSON")
            return
        }

        // Configure the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Make the network call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            // Print raw response data
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }

            // Parse the response
            if let result = try? JSONDecoder().decode(SentimentResponse.self, from: data) {
                DispatchQueue.main.async {
                    sentiment = result.mood ?? "not working"
                    print("Sentiment score: \(result.sentiment_score)")
                }
            } else {
                print("Failed to decode response")
            }
        }.resume()
    }
    
    
    // New struct to handle the suggestion response
        struct SuggestionResponse: Codable {
            let suggestion: String
        }

        func generateSuggestion() {
            // Backend URL for suggestion generation
            guard let url = URL(string: "https://bbcf-122-161-65-27.ngrok-free.app/generate") else {
                print("Invalid URL")
                return
            }

            // Create JSON data
            let requestBody: [String: String] = ["text": text]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                print("Failed to serialize JSON")
                return
            }

            // Configure the request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            // Make the network call
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("No data received")
                    return
                }

                // Print raw response data
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw Response: \(rawResponse)")
                }

                // Parse the response
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

#Preview {
  ContentView()
}
