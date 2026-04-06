//
//  Wallet.swift
//  BeforeZero
//
//  Created by acortino on 27/01/2026.
//

import Foundation

private enum DefaultsKey: String {
    case recurringItems = "SimpleExpenseTracker.recurringItems"
    case operations = "SimpleExpenseTracker.operations"
}

final class ExpenseManager: ObservableObject {

    @Published private(set) var recurringItems: [RecurringItem] = []
    @Published private(set) var currentAmount: Double = 0
    @Published private(set) var operations: [Operation] = []

    var initialAmount: Double {
        recurringItems.reduce(0) { partial, item in
            switch item.type {
            case .income:
                return partial + item.amount
            case .expense:
                return partial - item.amount
            }
        }
    }

    var hasCompletedSetup: Bool {
        !recurringItems.isEmpty
    }

    init() {
        loadFromDefaults()
        recomputeCurrent()
    }

    func setRecurringItems(_ items: [RecurringItem]) {
        recurringItems = items
        recomputeCurrent()
        persist()
    }

    func addRecurringItem(type: RecurringItemType, label: String, amount: Double) {
        guard amount > 0, !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        recurringItems.append(
            RecurringItem(type: type, label: label.trimmingCharacters(in: .whitespacesAndNewlines), amount: amount)
        )
        recomputeCurrent()
        persist()
    }

    func updateRecurringItem(_ updated: RecurringItem) {
        guard let index = recurringItems.firstIndex(where: { $0.id == updated.id }) else { return }
        recurringItems[index] = updated
        recomputeCurrent()
        persist()
    }

    func deleteRecurringItems(at offsets: IndexSet) {
        recurringItems.remove(atOffsets: offsets)
        recomputeCurrent()
        persist()
    }

    func addExpense(_ amount: Double, label: String) {
        guard amount > 0 else { return }
        operations.insert(Operation(type: .expense, amount: amount, label: label), at: 0)
        recomputeCurrent()
        persist()
    }

    func addInput(_ amount: Double, label: String) {
        guard amount > 0 else { return }
        operations.insert(Operation(type: .input, amount: amount, label: label), at: 0)
        recomputeCurrent()
        persist()
    }

    func resetToInitial() {
        guard hasCompletedSetup else { return }
        operations = []
        recomputeCurrent()
        persist()
    }

    func eraseAllData() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: DefaultsKey.recurringItems.rawValue)
        defaults.removeObject(forKey: DefaultsKey.operations.rawValue)

        recurringItems = []
        operations = []
        currentAmount = 0
    }

    private func recomputeCurrent() {
        var total = initialAmount

        for op in operations {
            switch op.type {
            case .expense:
                total -= op.amount
            case .input:
                total += op.amount
            }
        }

        currentAmount = total
    }

    private func loadFromDefaults() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: DefaultsKey.recurringItems.rawValue) {
            do {
                recurringItems = try JSONDecoder().decode([RecurringItem].self, from: data)
            } catch {
                recurringItems = []
            }
        }

        if let data = defaults.data(forKey: DefaultsKey.operations.rawValue) {
            do {
                operations = try JSONDecoder().decode([Operation].self, from: data)
            } catch {
                operations = []
            }
        }
    }

    private func persist() {
        let defaults = UserDefaults.standard

        do {
            let recurringData = try JSONEncoder().encode(recurringItems)
            defaults.set(recurringData, forKey: DefaultsKey.recurringItems.rawValue)
        } catch {
            defaults.removeObject(forKey: DefaultsKey.recurringItems.rawValue)
        }

        do {
            let operationsData = try JSONEncoder().encode(operations)
            defaults.set(operationsData, forKey: DefaultsKey.operations.rawValue)
        } catch {
            defaults.removeObject(forKey: DefaultsKey.operations.rawValue)
        }
    }
    
    func updateOperation(_ updated: Operation) {
        guard let index = operations.firstIndex(where: { $0.id == updated.id }) else { return }
        operations[index] = updated
        recomputeCurrent()
        persist()
    }

    func deleteOperation(_ operation: Operation) {
        operations.removeAll { $0.id == operation.id }
        recomputeCurrent()
        persist()
    }
}
