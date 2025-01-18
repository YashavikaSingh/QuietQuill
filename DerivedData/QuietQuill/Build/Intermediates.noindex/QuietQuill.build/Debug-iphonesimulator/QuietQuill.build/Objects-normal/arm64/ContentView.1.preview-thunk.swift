import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/yashavikasingh/QuietQuill/QuietQuill/ContentView.swift", line: 1)
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
            .navigationTitle(__designTimeString("#3225_0", fallback: "Calendar"))
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
                        .frame(height: __designTimeInteger("#3225_1", fallback: 50))
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
                                Text(__designTimeString("#3225_2", fallback: "Create Suggestion"))
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(__designTimeInteger("#3225_3", fallback: 10))
                            }
                            .padding()
                            
                            
                            
                            Text("Suggestion: \(suggestion)")
                                .padding()
                                .font(.headline)
                        }
                        
                        VStack{
                            Button(action: analyzeSentiment) {
                                Text(__designTimeString("#3225_4", fallback: "Analyze Sentiment"))
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(__designTimeInteger("#3225_5", fallback: 10))
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
                           Button(__designTimeString("#3225_6", fallback: "Done")) {
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
            try text.write(to: fileURL, atomically: __designTimeBoolean("#3225_7", fallback: true), encoding: .utf8)
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
            try title.write(to: fileURL, atomically: __designTimeBoolean("#3225_8", fallback: true), encoding: .utf8)
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
        dateFormatter.dateFormat = __designTimeString("#3225_9", fallback: "yyyy-MM-dd") // Use a simple date format suitable for filenames
        return dateFormatter.string(from: date)
    }

    
    
    struct SentimentResponse: Codable {
        let mood: String?
        let sentiment_score: Double?
    }

    func analyzeSentiment() {
        // Backend URL
        guard let url = URL(string: __designTimeString("#3225_10", fallback: "https://bbcf-122-161-65-27.ngrok-free.app/analyze_sentiment/")) else {
            print(__designTimeString("#3225_11", fallback: "Invalid URL"))
            return
        }

        // Create JSON data
        let requestBody: [String: String] = [__designTimeString("#3225_12", fallback: "note"): text]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print(__designTimeString("#3225_13", fallback: "Failed to serialize JSON"))
            return
        }

        // Configure the request
        var request = URLRequest(url: url)
        request.httpMethod = __designTimeString("#3225_14", fallback: "POST")
        request.setValue(__designTimeString("#3225_15", fallback: "application/json"), forHTTPHeaderField: __designTimeString("#3225_16", fallback: "Content-Type"))
        request.httpBody = jsonData

        // Make the network call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print(__designTimeString("#3225_17", fallback: "No data received"))
                return
            }

            // Print raw response data
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }

            // Parse the response
            if let result = try? JSONDecoder().decode(SentimentResponse.self, from: data) {
                DispatchQueue.main.async {
                    sentiment = result.mood ?? __designTimeString("#3225_18", fallback: "not working")
                    print("Sentiment score: \(result.sentiment_score)")
                }
            } else {
                print(__designTimeString("#3225_19", fallback: "Failed to decode response"))
            }
        }.resume()
    }
    
    
    // New struct to handle the suggestion response
        struct SuggestionResponse: Codable {
            let suggestion: String
        }

        func generateSuggestion() {
            // Backend URL for suggestion generation
            guard let url = URL(string: __designTimeString("#3225_20", fallback: "https://bbcf-122-161-65-27.ngrok-free.app/generate")) else {
                print(__designTimeString("#3225_21", fallback: "Invalid URL"))
                return
            }

            // Create JSON data
            let requestBody: [String: String] = [__designTimeString("#3225_22", fallback: "text"): text]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                print(__designTimeString("#3225_23", fallback: "Failed to serialize JSON"))
                return
            }

            // Configure the request
            var request = URLRequest(url: url)
            request.httpMethod = __designTimeString("#3225_24", fallback: "POST")
            request.setValue(__designTimeString("#3225_25", fallback: "application/json"), forHTTPHeaderField: __designTimeString("#3225_26", fallback: "Content-Type"))
            request.httpBody = jsonData

            // Make the network call
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print(__designTimeString("#3225_27", fallback: "No data received"))
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
                    print(__designTimeString("#3225_28", fallback: "Failed to decode response"))
                }
            }.resume()
        }
    
    
    func hideKeyboard() {
            isTextEditorFocused = __designTimeBoolean("#3225_29", fallback: false) // Unfocus the TextEditor to dismiss the keyboard
        }
}

#Preview {
  ContentView()
}
