//
//  BudgetOperation.swift
//  BeforeZero
//

import Foundation
import SwiftData

@Model
final class BudgetOperation {
    @Attribute(.unique) var id: UUID
    var date: Date
    var typeStorage: String
    var amount: Double
    var label: String

    // denormalized time bucket for fast queries
    var monthKey: Int

    var createdAt: Date
    var updatedAt: Date

    var month: BudgetMonth

    var type: OperationType {
        get { OperationType(rawValue: typeStorage) ?? .expense }
        set { typeStorage = newValue.rawValue }
    }

    var signedAmount: Double {
        amount * type.signedMultiplier
    }

    init(
        id: UUID = UUID(),
        date: Date = .now,
        type: OperationType,
        amount: Double,
        label: String,
        month: BudgetMonth,
        monthKey: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.typeStorage = type.rawValue
        self.amount = amount
        self.label = label
        self.month = month
        self.monthKey = monthKey
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
