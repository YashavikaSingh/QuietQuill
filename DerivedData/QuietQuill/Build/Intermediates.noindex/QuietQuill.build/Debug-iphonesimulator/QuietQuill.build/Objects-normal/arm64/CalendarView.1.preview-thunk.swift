import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/yashavikasingh/QuietQuill/QuietQuill/CalendarView.swift", line: 1)
//
//  CalendarView.swift
//  QuietQuill
//
//  Created by Yashavika Singh on 18.01.25.
//


import SwiftUI

struct CalendarView: View {
    let startYear = 2025
    let endYear = 2100
    var onDaySelected: (Date) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: __designTimeInteger("#11987_0", fallback: 20)) {
                ForEach(startYear...endYear, id: \.self) { year in
                    VStack(alignment: .leading, spacing: __designTimeInteger("#11987_1", fallback: 10)) {
                        Text("\(year)")
                            .font(.largeTitle)
                            .bold()
                            .padding(.leading)

                        ForEach(__designTimeInteger("#11987_2", fallback: 1)...__designTimeInteger("#11987_3", fallback: 12), id: \.self) { month in
                            MonthView(year: year, month: month, onDaySelected: onDaySelected)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct MonthView: View {
    let year: Int
    let month: Int
    var onDaySelected: (Date) -> Void

    private var daysInMonth: Int {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month)
        let date = calendar.date(from: dateComponents)!
        return calendar.range(of: .day, in: .month, for: date)!.count
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = __designTimeString("#11987_4", fallback: "MMMM")
        let dateComponents = DateComponents(year: year, month: month)
        let date = Calendar.current.date(from: dateComponents)!
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(monthName)
                .font(.title2)
                .padding(.leading)
                .padding(.top, __designTimeInteger("#11987_5", fallback: 10))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: __designTimeInteger("#11987_6", fallback: 10)), count: __designTimeInteger("#11987_7", fallback: 7)), spacing: __designTimeInteger("#11987_8", fallback: 10)) {
                ForEach(__designTimeInteger("#11987_9", fallback: 1)...daysInMonth, id: \.self) { day in
                    Button(action: {
                        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
                        onDaySelected(date)
                    }) {
                        Text("\(day)")
                            .frame(width: __designTimeInteger("#11987_10", fallback: 40), height: __designTimeInteger("#11987_11", fallback: 40))
                            .background(Color.blue.opacity(__designTimeFloat("#11987_12", fallback: 0.2)))
                            .cornerRadius(__designTimeInteger("#11987_13", fallback: 8))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarView(onDaySelected: { date in
        print("Selected date: \(date)")
    })
}
