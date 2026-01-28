//
//  Operation.swift
//  BeforeZero
//
//  Created by acortino on 28/01/2026.
//

import SwiftUI

struct AmountEntryView: View {
    let mode: EntryMode
    @State private var text = ""
    var onDone: (Double) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(mode == .expense ? "Expense amount" : "Income amount")) {
                    TextField("Enter amount", text: $text)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(mode == .expense ? "Add expense" : "Add input")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                        if let value = Double(text) {
                            onDone(value)
                        }
                    }
                    .disabled(Double(text) == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDone(0) }   // close without changes
                }
            }
        }
    }
}
