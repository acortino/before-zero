//
//  FirstRunSetup.swift
//  BeforeZero
//
//  Created by acortino on 28/01/2026.
//

import SwiftUI

struct FirstRunSetupView: View {
    @State private var text = ""
    var onComplete: (Double) -> Void

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
                Section(header: Text("Initial amount")) {
                    TextField("Enter starting amount", text: $text)
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
            .navigationTitle("Welcome")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        guard let value = parsedValue else { return }
                        onComplete(value)
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

