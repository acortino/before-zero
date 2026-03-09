//
//  RecurringItemType.swift
//  BeforeZero
//
//  Created by acortino on 09/03/2026.
//


import Foundation

enum RecurringItemType: String, Codable, CaseIterable, Identifiable {
    case income
    case expense

    var id: String { rawValue }

    var label: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        }
    }
}

struct RecurringItem: Identifiable, Codable, Equatable {
    let id: UUID
    var type: RecurringItemType
    var label: String
    var amount: Double

    init(id: UUID = UUID(), type: RecurringItemType, label: String, amount: Double) {
        self.id = id
        self.type = type
        self.label = label
        self.amount = amount
    }
}
