//
//  Homepage.swift
//  BeforeZero
//
//  Created by acortino on 27/01/2026.
//

import SwiftUI


enum EntryMode { case expense, input }

struct Homepage: View {
    // The manager lives for the whole app lifetime.
        @StateObject private var manager = ExpenseManager()

        // Helper to present a sheet for entering a number.
        @State private var showingEntrySheet = false
        @State private var entryMode: EntryMode = .expense   // .expense or .input

        var body: some View {
            VStack(spacing: 30) {
                Text("Current amount")
                    .font(.headline)

                Text("\(manager.currentAmount, specifier: "%.2f") €")
                    .font(.largeTitle)
                    .bold()

                HStack(spacing: 20) {
                    Button(action: {
                        entryMode = .expense
                        showingEntrySheet = true
                    }) {
                        Label("Add expense", systemImage: "minus.circle")
                    }

                    Button(action: {
                        entryMode = .input
                        showingEntrySheet = true
                    }) {
                        Label("Add input", systemImage: "plus.circle")
                    }

                    Button(action: {
                        manager.resetToInitial()
                    }) {
                        Label("Reset", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .sheet(isPresented: $showingEntrySheet) {
                AmountEntryView(mode: entryMode) { amount in
                    if entryMode == .expense {
                        manager.addExpense(amount)
                    } else {
                        manager.addInput(amount)
                    }
                    showingEntrySheet = false
                }
            }
            // Show the “first‑run” onboarding if no initial amount exists yet.
            .fullScreenCover(isPresented: .constant(manager.initialAmount == nil)) {
                FirstRunSetupView { amount in
                    manager.setInitialAmount(amount)
                }
            }
        }
}

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

#Preview {
    Homepage()
}
