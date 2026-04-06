//
//  Operation.swift
//  BeforeZero
//
//  Created by acortino on 14/02/2026.
//

import Foundation

enum OperationType: String, Codable {
    case expense
    case input
}

struct Operation: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: OperationType
    let amount: Double
    let label: String

    init(id: UUID = UUID(), type: OperationType, amount: Double, label: String, date: Date = Date()) {
        self.id = id
        self.date = date
        self.type = type
        self.amount = amount
        self.label = label
    }
}
