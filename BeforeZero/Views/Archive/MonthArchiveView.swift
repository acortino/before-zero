//
//  MonthArchiveView.swift
//  BeforeZero
//

import SwiftUI
import SwiftData

struct MonthArchiveView: View {
    private struct YearRow: Identifiable {
        let id: Int
        let year: Int
        let monthCount: Int
    }

    @Query(sort: [
        SortDescriptor(\BudgetMonth.yearMonthKey, order: .reverse)
    ])
    private var months: [BudgetMonth]

    private var yearRows: [YearRow] {
        Dictionary(grouping: months, by: \.year)
            .map { year, months in
                YearRow(id: year, year: year, monthCount: months.count)
            }
            .sorted { $0.year > $1.year }
    }

    var body: some View {
        List {
            if yearRows.isEmpty {
                Text("No archived months yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(yearRows) { row in
                    NavigationLink(value: AppRoute.year(row.year)) {
                        HStack {
                            Text("\(row.year)")
                            Spacer()
                            Text("\(row.monthCount) months")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Months")
    }
}
