//
//  RecurringTemplateItem.swift
//  BeforeZero
//

import Foundation
import SwiftData

@Model
final class RecurringTemplateItem {
    @Attribute(.unique) var id: UUID
    var typeStorage: String
    var label: String
    var amount: Double
    var sortOrder: Int
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    var type: RecurringItemType {
        get { RecurringItemType(rawValue: typeStorage) ?? .expense }
        set { typeStorage = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        type: RecurringItemType,
        label: String,
        amount: Double,
        sortOrder: Int = 0,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.typeStorage = type.rawValue
        self.label = label
        self.amount = amount
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
