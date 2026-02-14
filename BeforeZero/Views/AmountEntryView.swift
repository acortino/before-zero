//
//  Operation.swift
//  BeforeZero
//
//  Created by acortino on 28/01/2026.
//

import SwiftUI

struct AmountEntryView: View {
    let mode: EntryMode
    var onDone: ((Double, String)?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var labelText = ""

    private var parsedValue: Double? {
        CurrencyFormatting.parseUserNumber(amountText)
    }

    private var isValid: Bool {
        guard let v = parsedValue, v > 0 else { return false }
        return !labelText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(mode == .expense ? "Expense" : "Income")) {
                    TextField("Label (e.g. Groceries)", text: $labelText)

                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)

                    if !amountText.isEmpty && parsedValue == nil {
                        Text("Please enter a valid number")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(mode == .expense ? "Add expense" : "Add input")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let v = parsedValue else { return }
                        let label = labelText.trimmingCharacters(in: .whitespacesAndNewlines)
                        onDone((v, label))
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
