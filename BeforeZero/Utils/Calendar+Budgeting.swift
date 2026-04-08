//
//  Calendar+Budgeting.swift
//  BeforeZero
//

import Foundation

extension Calendar {
    func budgetMonthComponents(for date: Date) -> DateComponents {
        dateComponents([.year, .month], from: date)
    }

    func budgetMonthKey(for date: Date) -> Int {
        let components = budgetMonthComponents(for: date)
        return budgetMonthKey(year: components.year ?? 0, month: components.month ?? 0)
    }

    func budgetMonthKey(year: Int, month: Int) -> Int {
        (year * 100) + month
    }

    func budgetMonthStart(year: Int, month: Int) -> Date? {
        date(from: DateComponents(year: year, month: month, day: 1))
    }

    func budgetMonthTitle(year: Int, month: Int) -> String {
        guard let date = budgetMonthStart(year: year, month: month) else {
            return "\(month)/\(year)"
        }
        return BudgetMonthFormatter.shared.string(from: date)
    }
}

private enum BudgetMonthFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()
}
