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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Initial amount")) {
                    TextField("Enter starting amount", text: $text)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Welcome")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        if let value = Double(text) {
                            onComplete(value)
                        }
                    }
                    .disabled(Double(text) == nil)
                }
            }
        }
    }
}
