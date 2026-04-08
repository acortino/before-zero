//
//  Operation.swift
//  BeforeZero
//
//  Created by acortino on 28/01/2026.
//

import SwiftUI

struct AmountEntryView: View {
    let mode: EntryMode
    let existingOperation: BudgetOperation?
    var onDone: ((Double, String)?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String
    @State private var labelText: String

    init(
        mode: EntryMode,
        existingOperation: BudgetOperation? = nil,
        onDone: @escaping ((Double, String)?) -> Void
    ) {
        self.mode = mode
        self.existingOperation = existingOperation
        self.onDone = onDone

        _labelText = State(initialValue: existingOperation?.label ?? "")
        _amountText = State(initialValue: {
            guard let amount = existingOperation?.amount else { return "" }
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            return formatter.string(from: NSNumber(value: amount)) ?? ""
        }())
    }

    private var parsedValue: Double? {
        CurrencyFormatting.parseUserNumber(amountText)
    }

    private var isValid: Bool {
        guard let value = parsedValue, value > 0 else { return false }
        return !labelText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var sectionTitle: String {
        mode == .expense ? "Expense" : "Income"
    }

    private var navigationTitle: String {
        if existingOperation != nil {
            return mode == .expense ? "Edit expense" : "Edit input"
        } else {
            return mode == .expense ? "Add expense" : "Add input"
        }
    }

    private var saveButtonTitle: String {
        existingOperation != nil ? "Save" : "Add"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(sectionTitle) {
                    TextField("Label (e.g. Groceries)", text: $labelText)

                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)

                    if !amountText.isEmpty && parsedValue == nil {
                        Text("Please enter a valid number")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        guard let value = parsedValue else { return }
                        let trimmedLabel = labelText.trimmingCharacters(in: .whitespacesAndNewlines)
                        onDone((value, trimmedLabel))
                        dismiss()
                    }
                    .disabled(!isValid)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDone(nil)
                        dismiss()
                    }
                }
            }
        }
    }
}
