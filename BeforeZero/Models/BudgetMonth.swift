//
//  BudgetMonth.swift
//  BeforeZero
//

import Foundation
import SwiftData

@Model
final class BudgetMonth {
    @Attribute(.unique) var id: UUID
    var year: Int
    var month: Int
    @Attribute(.unique) var yearMonthKey: Int
    var baselineAmount: Double
    var createdAt: Date
    var closedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \BudgetOperation.month)
    var operations: [BudgetOperation]

    var displayTitle: String {
        Calendar.autoupdatingCurrent.budgetMonthTitle(year: year, month: month)
    }

    init(
        id: UUID = UUID(),
        year: Int,
        month: Int,
        baselineAmount: Double,
        createdAt: Date = .now,
        closedAt: Date? = nil,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.id = id
        self.year = year
        self.month = month
        self.yearMonthKey = calendar.budgetMonthKey(year: year, month: month)
        self.baselineAmount = baselineAmount
        self.createdAt = createdAt
        self.closedAt = closedAt
        self.operations = []
    }
}
