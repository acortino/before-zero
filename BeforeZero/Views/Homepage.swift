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
                    .accessibilityLabel("Add expense")
                    .accessibilityHint("Opens a sheet to record a new expense")

                    Button(action: {
                        entryMode = .input
                        showingEntrySheet = true
                    }) {
                        Label("Add input", systemImage: "plus.circle")
                    }
                    .accessibilityLabel("Add input")
                    .accessibilityHint("Opens a sheet to record a new input")

                    Button(action: {
                        manager.resetToInitial()
                    }) {
                        Label("Reset", systemImage: "arrow.clockwise")
                    }
                    .accessibilityLabel("Reset amount")
                    .accessibilityHint("Reset amount to the default value")
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



#Preview {
    Homepage()
}
