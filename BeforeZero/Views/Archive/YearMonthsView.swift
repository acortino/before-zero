//
//  YearMonthsView.swift
//  BeforeZero
//

import SwiftUI
import SwiftData

struct YearMonthsView: View {
    private struct MonthRow: Identifiable {
        let id: Int
        let monthKey: Int
        let title: String
        let baselineAmount: Double
    }

    private struct MonthRoute: Hashable {
        let monthKey: Int
    }

    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue
    @Query private var months: [BudgetMonth]

    let year: Int

    init(year: Int) {
        self.year = year

        let start = Calendar.autoupdatingCurrent.budgetMonthKey(year: year, month: 1)
        let end = Calendar.autoupdatingCurrent.budgetMonthKey(year: year, month: 12)
        _months = Query(
            filter: #Predicate<BudgetMonth> { month in
                month.yearMonthKey >= start && month.yearMonthKey <= end
            },
            sort: [
                SortDescriptor(\BudgetMonth.yearMonthKey, order: .reverse)
            ]
        )
    }

    private var currencyCode: String {
        (AppCurrency(rawValue: currencyRaw) ?? .eur).code
    }

    private var monthRows: [MonthRow] {
        months.map { month in
            MonthRow(
                id: month.yearMonthKey,
                monthKey: month.yearMonthKey,
                title: month.displayTitle,
                baselineAmount: month.baselineAmount
            )
        }
    }

    var body: some View {
        List {
            if monthRows.isEmpty {
                Text("No months recorded for \(year).")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(monthRows) { row in
                    NavigationLink(value: AppRoute.month(row.monthKey)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(row.title)
                                .font(.headline)

                            Text(summary(for: row))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("\(year)")
        .navigationDestination(for: MonthRoute.self) { route in
            MonthDetailsView(monthKey: route.monthKey)
        }
    }

    private func summary(for row: MonthRow) -> String {
        "Baseline \(CurrencyFormatting.formatCurrency(row.baselineAmount, code: currencyCode))"
    }
}
