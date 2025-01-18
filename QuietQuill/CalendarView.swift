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
            LazyVStack(spacing: 20) {
                ForEach(startYear...endYear, id: \.self) { year in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(year)")
                            .font(.largeTitle)
                            .bold()
                            .padding(.leading)

                        ForEach(1...12, id: \.self) { month in
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
        formatter.dateFormat = "MMMM"
        let dateComponents = DateComponents(year: year, month: month)
        let date = Calendar.current.date(from: dateComponents)!
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(monthName)
                .font(.title2)
                .padding(.leading)
                .padding(.top, 10)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    Button(action: {
                        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
                        onDaySelected(date)
                    }) {
                        Text("\(day)")
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
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