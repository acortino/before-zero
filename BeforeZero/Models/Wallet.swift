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
    case currentAmount = "SimpleExpenseTracker.currentAmount"
}

/// A tiny service that owns all expense‑related logic.
final class ExpenseManager: ObservableObject {

    // MARK: Public published properties (observed by SwiftUI)

    /// The amount shown on the home screen.
    @Published private(set) var currentAmount: Double = 0

    /// The amount that was first entered (used for “reset”). Nil until the user sets it.
    private(set) var initialAmount: Double? = nil

    // MARK: Init – load persisted values

    init() {
        loadFromDefaults()
    }

    // MARK: Public API

    /// Called once on first launch (or whenever the user wants to change the baseline).
    func setInitialAmount(_ amount: Double) {
        initialAmount = amount
        currentAmount = amount
        persist()
    }

    /// Add an expense → subtract from the total.
    func addExpense(_ amount: Double) {
        guard amount >= 0 else { return }
        currentAmount -= amount
        persist()
    }

    /// Add an income/input → increase the total.
    func addInput(_ amount: Double) {
        guard amount >= 0 else { return }
        currentAmount += amount
        persist()
    }

    /// Reset back to the original amount saved on first launch.
    func resetToInitial() {
        if let initial = initialAmount {
            currentAmount = initial
            persist()
        }
    }

    // MARK: Private persistence helpers

    private func loadFromDefaults() {
        let defaults = UserDefaults.standard
        if let storedInitial = defaults.object(forKey: DefaultsKey.initialAmount.rawValue) as? Double {
            initialAmount = storedInitial
            currentAmount = defaults.double(forKey: DefaultsKey.currentAmount.rawValue)
        }
    }

    private func persist() {
        guard let initial = initialAmount else { return }
        let defaults = UserDefaults.standard
        defaults.set(initial, forKey: DefaultsKey.initialAmount.rawValue)
        defaults.set(currentAmount, forKey: DefaultsKey.currentAmount.rawValue)
    }
}
