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
    @State private var showCalculationInfo = false

    private var currencyCode: String {
        (AppCurrency(rawValue: currencyRaw) ?? .eur).code
    }

    private var lastFiveOperations: [Operation] {
        Array(manager.operations.prefix(5))
    }
    
    private var totalManualInputs: Double {
        manager.operations
            .filter { $0.type == .input }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalManualExpenses: Double {
        manager.operations
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var calculationExplanation: String {
        """
        Current amount = Base monthly amount + Manual inputs - Manual expenses

        Base monthly amount: \(CurrencyFormatting.formatCurrency(manager.initialAmount, code: currencyCode))
        Manual inputs: \(CurrencyFormatting.formatCurrency(totalManualInputs, code: currencyCode))
        Manual expenses: \(CurrencyFormatting.formatCurrency(totalManualExpenses, code: currencyCode))
        Current amount: \(CurrencyFormatting.formatCurrency(manager.currentAmount, code: currencyCode))
        """
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
        .alert("Calculation details", isPresented: $showCalculationInfo) {
                   Button("OK", role: .cancel) { }
               } message: {
                   Text(calculationExplanation)
               }
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
        VStack(spacing: 16) {

            // MAIN AMOUNT
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(CurrencyFormatting.formatCurrency(manager.currentAmount, code: currencyCode))
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text("/")
                    .foregroundStyle(.secondary)

                Text(CurrencyFormatting.formatCurrency(manager.initialAmount, code: currencyCode))
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Button {
                    showCalculationInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // PROGRESS BAR
            GeometryReader { geo in
                let progress = max(0, min(manager.currentAmount / max(manager.initialAmount, 1), 1))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressColor(progress))
                        .frame(width: geo.size.width * progress, height: 10)
                }
            }
            .frame(height: 10)
        }
        .frame(maxWidth: .infinity)
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
    
    private func progressColor(_ progress: Double) -> Color {
        switch progress {
        case 0.5...:
            return .green
        case 0.2..<0.5:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    Homepage()
        .environmentObject(ExpenseManager())
}
