//
//  Operation.swift
//  BeforeZero
//
//  Created by acortino on 14/02/2026.
//

import Foundation

enum OperationType: String, Codable, CaseIterable, Identifiable {
    case expense
    case input

    var id: String { rawValue }

    var label: String {
        switch self {
        case .expense:
            return "Expense"
        case .input:
            return "Input"
        }
    }

    var signedMultiplier: Double {
        switch self {
        case .expense:
            return -1
        case .input:
            return 1
        }
    }
}
