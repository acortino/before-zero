//
//  Homepage.swift
//  BeforeZero
//
//  Created by acortino on 27/01/2026.
//

import SwiftUI


enum EntryMode { case expense, input }

struct Homepage: View {
    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue

    // The manager lives for the whole app lifetime.
        @StateObject private var manager = ExpenseManager()

        // Helper to present a sheet for entering a number.
        @State private var showingEntrySheet = false
        @State private var entryMode: EntryMode = .expense   // .expense or .input
        @State private var showResetConfirm = false
    
    private var currencyCode: String {
        (AppCurrency(rawValue: currencyRaw) ?? .eur).code
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Current amount")
                    .font(.headline)
                
                Text(CurrencyFormatting.formatCurrency(manager.currentAmount, code: currencyCode))
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
                    
                    Button {
                        showResetConfirm = true
                    } label: {
                        Label("Reset", systemImage: "arrow.clockwise")
                    }
                    .accessibilityLabel("Reset amount")
                    .accessibilityHint("Reset amount to the default value")
                    .confirmationDialog("Confirm reset?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                        Button("Reset amount", role: .destructive) {
                            manager.resetToInitial()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will set the amount back to the default value.")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("BeforeZero")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                NavigationLink {
                                    SettingsView()
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                                .accessibilityLabel("Settings")
                            }
                        }
                        .sheet(isPresented: $showingEntrySheet) {
                            AmountEntryView(mode: entryMode) { amount in
                                guard let amount else { return } // cancel
                                if entryMode == .expense { manager.addExpense(amount) }
                                else { manager.addInput(amount) }
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
}

#Preview {
    Homepage()
}
