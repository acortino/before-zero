//
//  Operation.swift
//  BeforeZero
//
//  Created by acortino on 28/01/2026.
//

import SwiftUI

import SwiftUI

struct AmountEntryView: View {
    let mode: EntryMode
    var onDone: (Double?) -> Void  // nil = cancel

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue
    private var currencyCode: String { (AppCurrency(rawValue: currencyRaw) ?? .eur).code }

    private var parsedValue: Double? {
        CurrencyFormatting.parseUserNumber(text)
    }

    private var isValid: Bool {
        guard let v = parsedValue else { return false }
        return v > 0
    }

    private var preview: String {
        guard let v = parsedValue else { return "—" }
        return CurrencyFormatting.formatCurrency(v, code: currencyCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(mode == .expense ? "Expense amount" : "Income amount")) {
                    TextField("Enter amount", text: $text)
                        .keyboardType(.decimalPad)

                    HStack {
                        Text("Preview")
                        Spacer()
                        Text(preview)
                            .foregroundStyle(.secondary)
                    }

                    if !text.isEmpty && !isValid {
                        Text("Please enter a valid positive number")
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
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onDone(v)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onDone(nil)
                        dismiss()
                    }
                }
            }
        }
    }
}
