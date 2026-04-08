//
//  RecurringTemplateDraft.swift
//  BeforeZero
//

import Foundation

struct RecurringTemplateDraft: Identifiable, Equatable {
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

    init(template: RecurringTemplateItem) {
        self.id = template.id
        self.type = template.type
        self.label = template.label
        self.amount = template.amount
    }
}
