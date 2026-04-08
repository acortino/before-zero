//
//  BudgetRepository.swift
//  BeforeZero
//

import Foundation
import SwiftData

enum BudgetRepositoryError: LocalizedError {
    case invalidAmount
    case emptyLabel

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Amounts must be greater than zero."
        case .emptyLabel:
            return "Labels cannot be empty."
        }
    }
}

@MainActor
struct BudgetRepository {
    let context: ModelContext
    let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .autoupdatingCurrent) {
        self.context = context
        self.calendar = calendar
    }

    func month(monthKey: Int) throws -> BudgetMonth? {
        var descriptor = FetchDescriptor<BudgetMonth>(
            predicate: #Predicate<BudgetMonth> { budgetMonth in
                budgetMonth.yearMonthKey == monthKey
            },
            sortBy: [SortDescriptor(\BudgetMonth.yearMonthKey, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func month(year: Int, month: Int) throws -> BudgetMonth? {
        let key = calendar.budgetMonthKey(year: year, month: month)
        return try self.month(monthKey: key)
    }

    func allMonths() throws -> [BudgetMonth] {
        let descriptor = FetchDescriptor<BudgetMonth>(
            sortBy: [SortDescriptor(\BudgetMonth.yearMonthKey, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func hasActiveRecurringTemplateItems() throws -> Bool {
        var descriptor = FetchDescriptor<RecurringTemplateItem>(
            predicate: #Predicate<RecurringTemplateItem> { item in
                item.isActive == true
            }
        )
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    func months(forYear year: Int) throws -> [BudgetMonth] {
        let start = calendar.budgetMonthKey(year: year, month: 1)
        let end = calendar.budgetMonthKey(year: year, month: 12)
        let descriptor = FetchDescriptor<BudgetMonth>(
            predicate: #Predicate<BudgetMonth> { budgetMonth in
                budgetMonth.yearMonthKey >= start && budgetMonth.yearMonthKey <= end
            },
            sortBy: [SortDescriptor(\BudgetMonth.yearMonthKey, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func createMonthIfNeeded(for date: Date) throws -> BudgetMonth {
        let components = calendar.budgetMonthComponents(for: date)
        let year = components.year ?? 0
        let monthNumber = components.month ?? 1

        if let existing = try month(year: year, month: monthNumber) {
            return existing
        }

        let baselineAmount = try baselineForNewMonth()
        let newMonth = BudgetMonth(
            year: year,
            month: monthNumber,
            baselineAmount: baselineAmount,
            createdAt: date,
            calendar: calendar
        )
        context.insert(newMonth)
        closeHistoricalMonths(before: newMonth.yearMonthKey, closedAt: date)
        try saveIfNeeded()
        return newMonth
    }

    func activeRecurringTemplateItems() throws -> [RecurringTemplateItem] {
        let descriptor = FetchDescriptor<RecurringTemplateItem>(
            predicate: #Predicate<RecurringTemplateItem> { item in
                item.isActive == true
            },
            sortBy: [
                SortDescriptor(\RecurringTemplateItem.sortOrder, order: .forward),
                SortDescriptor(\RecurringTemplateItem.createdAt, order: .forward)
            ]
        )
        return try context.fetch(descriptor)
    }

    func baselineForNewMonth() throws -> Double {
        let activeTemplates = try activeRecurringTemplateItems()
        let baseline = activeTemplates.reduce(0) { partial, item in
            switch item.type {
            case .income:
                return partial + item.amount
            case .expense:
                return partial - item.amount
            }
        }
        return baseline
    }

    @discardableResult
    func addOperation(
        to month: BudgetMonth,
        type: OperationType,
        amount: Double,
        label: String,
        date: Date = .now
    ) throws -> BudgetOperation {
        try addOperation(
            to: month,
            id: UUID(),
            type: type,
            amount: amount,
            label: label,
            date: date,
            createdAt: .now,
            updatedAt: .now
        )
    }

    @discardableResult
    func addOperation(
        to month: BudgetMonth,
        id: UUID,
        type: OperationType,
        amount: Double,
        label: String,
        date: Date,
        createdAt: Date,
        updatedAt: Date
    ) throws -> BudgetOperation {
        let sanitizedLabel = sanitizeLabel(label)
        guard amount > 0 else { throw BudgetRepositoryError.invalidAmount }
        guard !sanitizedLabel.isEmpty else { throw BudgetRepositoryError.emptyLabel }

        let operation = BudgetOperation(
            id: id,
            date: date,
            type: type,
            amount: amount,
            label: sanitizedLabel,
            month: month,
            monthKey: month.yearMonthKey,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        context.insert(operation)
        try saveIfNeeded()
        return operation
    }

    func updateOperation(
        _ operation: BudgetOperation,
        type: OperationType? = nil,
        amount: Double,
        label: String,
        date: Date
    ) throws {
        let sanitizedLabel = sanitizeLabel(label)
        guard amount > 0 else { throw BudgetRepositoryError.invalidAmount }
        guard !sanitizedLabel.isEmpty else { throw BudgetRepositoryError.emptyLabel }

        if let type {
            operation.type = type
        }
        operation.amount = amount
        operation.label = sanitizedLabel
        operation.date = date
        operation.updatedAt = .now
        try saveIfNeeded()
    }

    func deleteOperation(_ operation: BudgetOperation) throws {
        context.delete(operation)
        try saveIfNeeded()
    }

    func recurringTemplateItems() throws -> [RecurringTemplateItem] {
        let descriptor = FetchDescriptor<RecurringTemplateItem>(
            sortBy: [
                SortDescriptor(\RecurringTemplateItem.sortOrder, order: .forward),
                SortDescriptor(\RecurringTemplateItem.createdAt, order: .forward)
            ]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func completeInitialSetup(
        with items: [RecurringTemplateDraft],
        for date: Date = .now
    ) throws -> BudgetMonth {
        try replaceRecurringTemplateItems(items)
        try saveIfNeeded()

        let computedBaseline = try baselineForNewMonth()

        if let existingMonth = try currentMonthIfExists(for: date) {
            let hasOperations = try hasOperations(forMonthKey: existingMonth.yearMonthKey)
            if !hasOperations && existingMonth.baselineAmount == 0 {
                existingMonth.baselineAmount = computedBaseline
                existingMonth.createdAt = date
                try saveIfNeeded()
            }
            return existingMonth
        }

        let components = calendar.budgetMonthComponents(for: date)
        let year = components.year ?? 0
        let monthNumber = components.month ?? 1

        let newMonth = BudgetMonth(
            year: year,
            month: monthNumber,
            baselineAmount: computedBaseline,
            createdAt: date,
            calendar: calendar
        )
        context.insert(newMonth)
        closeHistoricalMonths(before: newMonth.yearMonthKey, closedAt: date)
        try saveIfNeeded()
        return newMonth
    }

    func replaceRecurringTemplateItems(_ items: [RecurringTemplateDraft]) throws {
        let existing = try recurringTemplateItems()
        for template in existing {
            context.delete(template)
        }

        let timestamp = Date.now
        for (index, item) in items.enumerated() {
            let sanitizedLabel = sanitizeLabel(item.label)
            guard item.amount > 0 else { continue }
            guard !sanitizedLabel.isEmpty else { continue }

            let template = RecurringTemplateItem(
                id: item.id,
                type: item.type,
                label: sanitizedLabel,
                amount: item.amount,
                sortOrder: index,
                isActive: true,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            context.insert(template)
        }

        try saveIfNeeded()
    }

    func currentAmount(baselineAmount: Double, operations: [BudgetOperation]) -> Double {
        baselineAmount + operations.reduce(0) { partial, operation in
            partial + operation.signedAmount
        }
    }

    func currentAmount(for month: BudgetMonth) -> Double {
        let operations = (try? operations(forMonthKey: month.yearMonthKey)) ?? []
        return currentAmount(baselineAmount: month.baselineAmount, operations: operations)
    }

    func currentAmount(for month: BudgetMonth, operations: [BudgetOperation]) -> Double {
        currentAmount(baselineAmount: month.baselineAmount, operations: operations)
    }

    func runningBalances(
        baselineAmount: Double,
        operations: [BudgetOperation]
    ) -> [BudgetOperationBalance] {
        let chronological = operations.sorted(by: chronologicalSort)
        var balance = baselineAmount

        return chronological.map { operation in
            balance += operation.signedAmount
            return BudgetOperationBalance(operation: operation, balanceAfter: balance)
        }
    }

    func runningBalances(
        for month: BudgetMonth,
        operations: [BudgetOperation]
    ) -> [BudgetOperationBalance] {
        runningBalances(baselineAmount: month.baselineAmount, operations: operations)
    }

    func topExpenses(limit: Int) throws -> [BudgetOperation] {
        Array(try operationsAllTime(filter: .expense, sort: .amountDescending).prefix(limit))
    }

    func topExpenses(limit: Int, for month: BudgetMonth) throws -> [BudgetOperation] {
        Array(try operations(for: month, filter: .expense, sort: .amountDescending).prefix(limit))
    }

    func averageExpense() throws -> Double {
        let expenses = try operationsAllTime(filter: .expense, sort: .amountDescending)
        return averageAmount(for: expenses)
    }

    func averageExpense(for month: BudgetMonth) throws -> Double {
        let expenses = try operations(for: month, filter: .expense, sort: .amountDescending)
        return averageAmount(for: expenses)
    }

    func totals(forMonthKey monthKey: Int) throws -> (inputs: Double, expenses: Double) {
        let operations = try operations(forMonthKey: monthKey)
        return operations.reduce(into: (inputs: 0.0, expenses: 0.0)) { partial, operation in
            switch operation.type {
            case .expense:
                partial.expenses += operation.amount
            case .input:
                partial.inputs += operation.amount
            }
        }
    }

    func totals(for month: BudgetMonth) throws -> (inputs: Double, expenses: Double) {
        try totals(forMonthKey: month.yearMonthKey)
    }

    func operations(
        forMonthKey monthKey: Int,
        filter: BudgetOperationFilter = .all,
        sort: BudgetOperationSort = .dateDescending
    ) throws -> [BudgetOperation] {
        try context.fetch(monthOperationDescriptor(monthKey: monthKey, filter: filter, sort: sort))
    }

    func operations(
        for month: BudgetMonth,
        filter: BudgetOperationFilter = .all,
        sort: BudgetOperationSort = .dateDescending
    ) throws -> [BudgetOperation] {
        try operations(forMonthKey: month.yearMonthKey, filter: filter, sort: sort)
    }

    func operations(
        forYear year: Int,
        filter: BudgetOperationFilter = .all,
        sort: BudgetOperationSort = .dateDescending
    ) throws -> [BudgetOperation] {
        let start = calendar.budgetMonthKey(year: year, month: 1)
        let end = calendar.budgetMonthKey(year: year, month: 12)
        return try context.fetch(yearOperationDescriptor(start: start, end: end, filter: filter, sort: sort))
    }

    func operationsAllTime(
        filter: BudgetOperationFilter = .all,
        sort: BudgetOperationSort = .dateDescending
    ) throws -> [BudgetOperation] {
        try context.fetch(allTimeOperationDescriptor(filter: filter, sort: sort))
    }

    func eraseAllData() throws {
        try allMonths().forEach(context.delete)
        try recurringTemplateItems().forEach(context.delete)
        try saveIfNeeded()
    }

    private func saveIfNeeded() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    private func hasOperations(forMonthKey monthKey: Int) throws -> Bool {
        var descriptor = FetchDescriptor<BudgetOperation>(
            predicate: #Predicate<BudgetOperation> { operation in
                operation.monthKey == monthKey
            }
        )
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    private func sanitizeLabel(_ label: String) -> String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func averageAmount(for operations: [BudgetOperation]) -> Double {
        guard !operations.isEmpty else { return 0 }
        let total = operations.reduce(0) { $0 + $1.amount }
        return total / Double(operations.count)
    }

    private func closeHistoricalMonths(before key: Int, closedAt: Date) {
        let descriptor = FetchDescriptor<BudgetMonth>(
            predicate: #Predicate<BudgetMonth> { budgetMonth in
                budgetMonth.yearMonthKey < key && budgetMonth.closedAt == nil
            }
        )

        do {
            let historicalMonths = try context.fetch(descriptor)
            for historicalMonth in historicalMonths {
                historicalMonth.closedAt = closedAt
            }
        } catch {
            return
        }
    }

    private func chronologicalSort(_ lhs: BudgetOperation, _ rhs: BudgetOperation) -> Bool {
        if lhs.date == rhs.date {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.date < rhs.date
    }

    private func monthOperationDescriptor(
        monthKey: Int,
        filter: BudgetOperationFilter,
        sort: BudgetOperationSort
    ) -> FetchDescriptor<BudgetOperation> {
        let expenseRawValue = OperationType.expense.rawValue
        let inputRawValue = OperationType.input.rawValue

        switch filter {
        case .all:
            return FetchDescriptor<BudgetOperation>(
                predicate: #Predicate<BudgetOperation> { operation in
                    operation.monthKey == monthKey
                },
                sortBy: sort.sortDescriptors
            )
        case .expense:
            return FetchDescriptor<BudgetOperation>(
                predicate: #Predicate<BudgetOperation> { operation in
                    operation.monthKey == monthKey &&
                    operation.typeStorage == expenseRawValue
                },
                sortBy: sort.sortDescriptors
            )
        case .input:
            return FetchDescriptor<BudgetOperation>(
                predicate: #Predicate<BudgetOperation> { operation in
                    operation.monthKey == monthKey &&
                    operation.typeStorage == inputRawValue
                },
                sortBy: sort.sortDescriptors
            )
        }
    }

    private func yearOperationDescriptor(
        start: Int,
        end: Int,
        filter: BudgetOperationFilter,
        sort: BudgetOperationSort
    ) -> FetchDescriptor<BudgetOperation> {
        let expenseRawValue = OperationType.expense.rawValue
        let inputRawValue = OperationType.input.rawValue

        switch filter {
        case .all:
            return FetchDescriptor<BudgetOperation>(
                predicate: #Predicate<BudgetOperation> { operation in
                    operation.monthKey >= start && operation.monthKey <= end
                },
                sortBy: sort.sortDescriptors
            )
        case .expense:
            return FetchDescriptor<BudgetOperation>(
                predicate: #Predicate<BudgetOperation> { operation in
                    operation.monthKey >= start &&
                    operation.monthKey <= end &&
                    operation.typeStorage == expenseRawValue
                },
                sortBy: sort.sortDescriptors
            )
        case .input:
            return FetchDescriptor<BudgetOperation>(
                predicate: #Predicate<BudgetOperation> { operation in
                    operation.monthKey >= start &&
                    operation.monthKey <= end &&
                    operation.typeStorage == inputRawValue
                },
                sortBy: sort.sortDescriptors
            )
        }
    }

    private func allTimeOperationDescriptor(
        filter: BudgetOperationFilter,
        sort: BudgetOperationSort
    ) -> FetchDescriptor<BudgetOperation> {
        let expenseRawValue = OperationType.expense.rawValue
        let inputRawValue = OperationType.input.rawValue

        switch filter {
        case .all:
            return FetchDescriptor<BudgetOperation>(sortBy: sort.sortDescriptors)
        case .expense:
            return FetchDescriptor<BudgetOperation>(
                predicate: #Predicate<BudgetOperation> { operation in
                    operation.typeStorage == expenseRawValue
                },
                sortBy: sort.sortDescriptors
            )
        case .input:
            return FetchDescriptor<BudgetOperation>(
                predicate: #Predicate<BudgetOperation> { operation in
                    operation.typeStorage == inputRawValue
                },
                sortBy: sort.sortDescriptors
            )
        }
    }
    
    func currentMonthIfExists(for date: Date) throws -> BudgetMonth? {
        let components = calendar.budgetMonthComponents(for: date)
        let year = components.year ?? 0
        let monthNumber = components.month ?? 1
        return try month(year: year, month: monthNumber)
    }
}
