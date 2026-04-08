//
//  BudgetQueryModels.swift
//  BeforeZero
//

import Foundation
import SwiftData

enum BudgetOperationFilter: String, CaseIterable, Identifiable {
    case all
    case expense
    case input

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            return "All"
        case .expense:
            return "Expenses"
        case .input:
            return "Inputs"
        }
    }

    func matches(_ operation: BudgetOperation) -> Bool {
        switch self {
        case .all:
            return true
        case .expense:
            return operation.type == .expense
        case .input:
            return operation.type == .input
        }
    }
}

enum BudgetOperationSort: String, CaseIterable, Identifiable {
    case dateDescending
    case dateAscending
    case amountDescending
    case amountAscending
    case labelAscending
    case labelDescending

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dateDescending:
            return "Newest first"
        case .dateAscending:
            return "Oldest first"
        case .amountDescending:
            return "Highest amount"
        case .amountAscending:
            return "Lowest amount"
        case .labelAscending:
            return "Label A-Z"
        case .labelDescending:
            return "Label Z-A"
        }
    }

    var sortDescriptors: [SortDescriptor<BudgetOperation>] {
        switch self {
        case .dateDescending:
            return [
                SortDescriptor(\BudgetOperation.date, order: .reverse),
                SortDescriptor(\BudgetOperation.createdAt, order: .reverse)
            ]
        case .dateAscending:
            return [
                SortDescriptor(\BudgetOperation.date, order: .forward),
                SortDescriptor(\BudgetOperation.createdAt, order: .forward)
            ]
        case .amountDescending:
            return [
                SortDescriptor(\BudgetOperation.amount, order: .reverse),
                SortDescriptor(\BudgetOperation.date, order: .reverse)
            ]
        case .amountAscending:
            return [
                SortDescriptor(\BudgetOperation.amount, order: .forward),
                SortDescriptor(\BudgetOperation.date, order: .forward)
            ]
        case .labelAscending:
            return [
                SortDescriptor(\BudgetOperation.label, order: .forward),
                SortDescriptor(\BudgetOperation.date, order: .reverse)
            ]
        case .labelDescending:
            return [
                SortDescriptor(\BudgetOperation.label, order: .reverse),
                SortDescriptor(\BudgetOperation.date, order: .reverse)
            ]
        }
    }

    func comparator(lhs: BudgetOperation, rhs: BudgetOperation) -> Bool {
        switch self {
        case .dateDescending:
            return orderedDates(lhs, rhs, ascending: false)
        case .dateAscending:
            return orderedDates(lhs, rhs, ascending: true)
        case .amountDescending:
            if lhs.amount == rhs.amount {
                return orderedDates(lhs, rhs, ascending: false)
            }
            return lhs.amount > rhs.amount
        case .amountAscending:
            if lhs.amount == rhs.amount {
                return orderedDates(lhs, rhs, ascending: true)
            }
            return lhs.amount < rhs.amount
        case .labelAscending:
            let comparison = lhs.label.localizedCaseInsensitiveCompare(rhs.label)
            if comparison == .orderedSame {
                return orderedDates(lhs, rhs, ascending: false)
            }
            return comparison == .orderedAscending
        case .labelDescending:
            let comparison = lhs.label.localizedCaseInsensitiveCompare(rhs.label)
            if comparison == .orderedSame {
                return orderedDates(lhs, rhs, ascending: false)
            }
            return comparison == .orderedDescending
        }
    }

    private func orderedDates(_ lhs: BudgetOperation, _ rhs: BudgetOperation, ascending: Bool) -> Bool {
        if lhs.date == rhs.date {
            return ascending ? lhs.createdAt < rhs.createdAt : lhs.createdAt > rhs.createdAt
        }
        return ascending ? lhs.date < rhs.date : lhs.date > rhs.date
    }
}

struct BudgetOperationBalance: Identifiable {
    let operation: BudgetOperation
    let balanceAfter: Double

    var id: UUID { operation.id }
}
