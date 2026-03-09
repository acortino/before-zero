//
//  Wallet.swift
//  BeforeZero
//
//  Created by acortino on 27/01/2026.
//

import Foundation

/// Keys used in UserDefaults – keep them private to avoid collisions.
private enum DefaultsKey: String {
    case initialAmount = "SimpleExpenseTracker.initialAmount"
    case operations = "SimpleExpenseTracker.operations"
}


/// A tiny service that owns all expense‑related logic.
import Foundation

final class ExpenseManager: ObservableObject {

    @Published private(set) var currentAmount: Double = 0
    @Published private(set) var initialAmount: Double? = nil
    @Published private(set) var operations: [Operation] = [] 

    init() {
        loadFromDefaults()
        recomputeCurrent()
    }

    func setInitialAmount(_ amount: Double) {
        initialAmount = amount
        operations = []
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
        guard initialAmount != nil else { return }
        operations = []
        recomputeCurrent()
        persist()
    }

    // MARK: - Private

    private func recomputeCurrent() {
        guard let initialAmount else {
            currentAmount = 0
            return
        }

        var total = initialAmount
        for op in operations {
            switch op.type {
            case .expense: total -= op.amount
            case .input: total += op.amount
            }
        }
        currentAmount = total
    }

    private func loadFromDefaults() {
        let defaults = UserDefaults.standard

        if let storedInitial = defaults.object(forKey: DefaultsKey.initialAmount.rawValue) as? Double {
            initialAmount = storedInitial
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

        if let initialAmount {
            defaults.set(initialAmount, forKey: DefaultsKey.initialAmount.rawValue)
        } else {
            defaults.removeObject(forKey: DefaultsKey.initialAmount.rawValue)
        }

        do {
            let data = try JSONEncoder().encode(operations)
            defaults.set(data, forKey: DefaultsKey.operations.rawValue)
        } catch {
            // If encoding fails, don't crash; you could log in debug.
        }
    }
    
    func eraseAllData() {
        let defaults = UserDefaults.standard

        defaults.removeObject(forKey: DefaultsKey.initialAmount.rawValue)
        defaults.removeObject(forKey: DefaultsKey.operations.rawValue)

        initialAmount = nil
        operations = []
        currentAmount = 0
    }
    
}
