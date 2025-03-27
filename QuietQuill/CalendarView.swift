import SwiftUI

struct CalendarView: View {
    let startYear = 2025
    let endYear = 2100
    var onDaySelected: (Date) -> Void
    
    // Color palette
    private let backgroundColor = Color(hexString: "FBF7F4")
    private let primaryColor = Color(hexString: "3C6E71")
    private let accentColor = Color(hexString: "ECCC61")
    private let savedDateColor = Color(hexString: "A1683A")
    private let textColor = Color(hexString: "210F04")
    
    @State private var savedDates: Set<Date> = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(startYear...endYear, id: \.self) { year in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(year)")
                            .font(.largeTitle)
                            .bold()
                            .padding(.leading)
                            .foregroundColor(primaryColor)

                        ForEach(1...12, id: \.self) { month in
                            MonthView(
                                year: year, 
                                month: month, 
                                savedDates: $savedDates,
                                onDaySelected: onDaySelected,
                                primaryColor: primaryColor,
                                accentColor: accentColor,
                                savedDateColor: savedDateColor,
                                textColor: textColor
                            )
                        }
                    }
                }
            }
            .padding()
            .background(backgroundColor)
        }
        .onAppear {
            loadSavedDates()
        }
    }
    
    private func loadSavedDates() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            
            let textFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix("text_") }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            savedDates = Set(textFiles.compactMap { fileURL in
                let filename = fileURL.lastPathComponent
                let dateString = filename.replacingOccurrences(of: "text_", with: "").replacingOccurrences(of: ".txt", with: "")
                return dateFormatter.date(from: dateString)
            })
        } catch {
            print("Error loading saved dates: \(error)")
        }
    }
}

struct MonthView: View {
    let year: Int
    let month: Int
    @Binding var savedDates: Set<Date>
    var onDaySelected: (Date) -> Void
    
    // Color parameters
    let primaryColor: Color
    let accentColor: Color
    let savedDateColor: Color
    let textColor: Color

    private var daysInMonth: Int {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month)
        let date = calendar.date(from: dateComponents)!
        return calendar.range(of: .day, in: .month, for: date)!.count
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let dateComponents = DateComponents(year: year, month: month)
        let date = Calendar.current.date(from: dateComponents)!
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(monthName)
                .font(.title2)
                .foregroundColor(primaryColor)
                .padding(.leading)
                .padding(.top, 10)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    let currentDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
                    
                    Button(action: {
                        onDaySelected(currentDate)
                    }) {
                        Text("\(day)")
                            .frame(width: 40, height: 40)
                            .background(savedDates.contains(currentDate) ? savedDateColor.opacity(0.3) : accentColor.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(textColor)
                    }
                }
            }
        }
    }
}

// Extension to resolve ambiguous hex color initialization
extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
            (a, r, g, b) = (255, 0, 0, 0)
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

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}


#Preview {
    CalendarView(onDaySelected: { date in
        print("Selected date: \(date)")
    })
}