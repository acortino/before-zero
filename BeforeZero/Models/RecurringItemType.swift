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
