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

    private var parsedValue: Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        guard let value = parsedValue else { return false }
        return value > 0
    }
    
    private func sanitize(_ input: String) -> String {
        // Normalize decimal separator
        let normalized = input.replacingOccurrences(of: ",", with: ".")

        // Allow only digits and one dot
        var result = ""
        var hasDot = false
        var decimalCount = 0

        for char in normalized {
            if char.isWholeNumber {
                if hasDot {
                    if decimalCount < 2 {
                        result.append(char)
                        decimalCount += 1
                    }
                } else {
                    result.append(char)
                }
            } else if char == "." && !hasDot {
                hasDot = true
                result.append(char)
            }
        }

        return result
    }

    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(mode == .expense ? "Expense amount" : "Income amount")) {
                    TextField("Enter amount", text: $text)
                        .keyboardType(.decimalPad)
                        .onChange(of: text) { _,newValue in
                            text = sanitize(newValue)
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
                        guard let value = parsedValue else { return }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                        if let value = Double(text) {
                            onDone(value)
                        }
                    }
                    .disabled(!isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDone(0) }   // close without changes
                }
            }
        }
    }
}
