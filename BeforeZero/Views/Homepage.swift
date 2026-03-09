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

    @EnvironmentObject var manager: ExpenseManager

    @State private var showingEntrySheet = false
    @State private var entryMode: EntryMode = .expense
    @State private var showResetConfirm = false

    private var currencyCode: String {
        (AppCurrency(rawValue: currencyRaw) ?? .eur).code
    }

    private var lastFiveOperations: [Operation] {
        Array(manager.operations.prefix(5))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("BeforeZero")
                .toolbar { settingsToolbar }
                .padding()
        }
        .sheet(isPresented: $showingEntrySheet) { entrySheet }
        .fullScreenCover(isPresented: onboardingBinding) { onboardingView }
    }

    // MARK: - Subviews

    private var content: some View {
        VStack(spacing: 24) {
            header
            actionButtons
            recentActivity
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Current amount")
                .font(.headline)

            Text(CurrencyFormatting.formatCurrency(manager.currentAmount, code: currencyCode))
                .font(.largeTitle)
                .bold()
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                entryMode = .expense
                showingEntrySheet = true
            } label: {
                Label("Add expense", systemImage: "minus.circle")
            }

            Button {
                entryMode = .input
                showingEntrySheet = true
            } label: {
                Label("Add input", systemImage: "plus.circle")
            }

            Button {
                showResetConfirm = true
            } label: {
                Label("Start a new month", systemImage: "arrow.clockwise")
            }
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

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent activity")
                .font(.headline)

            if lastFiveOperations.isEmpty {
                Text("No operations yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(lastFiveOperations) { op in
                    operationRow(op)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func operationRow(_ op: Operation) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(op.label)
                Text(op.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(CurrencyFormatting.formatCurrency(op.amount, code: currencyCode))
                .foregroundStyle(op.type == .expense ? .red : .green)
        }
        .padding(.vertical, 6)
    }

    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }

    private var entrySheet: some View {
        AmountEntryView(mode: entryMode) { result in
            guard let (amount, label) = result else { return }
            if entryMode == .expense {
                manager.addExpense(amount, label: label)
            } else {
                manager.addInput(amount, label: label)
            }
            showingEntrySheet = false
        }
    }

    // MARK: - Onboarding

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !manager.hasCompletedSetup },
            set: { _ in }
        )
    }
    
    private var onboardingView: some View {
          FirstRunSetupView { items in
              manager.setRecurringItems(items)
          }
      }
}

#Preview {
    Homepage()
        .environmentObject(ExpenseManager())
}
