//
//  FirstRunSetup.swift
//  BeforeZero
//
//  Created by acortino on 28/01/2026.
//

import SwiftUI

struct FirstRunSetupView: View {
    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue

    @State private var items: [RecurringTemplateDraft] = []

    var onComplete: ([RecurringTemplateDraft]) -> Void

    private var currencyCode: String {
        (AppCurrency(rawValue: currencyRaw) ?? .eur).code
    }

    private var incomeIndices: [Int] {
        items.indices.filter { items[$0].type == .income }
    }

    private var expenseIndices: [Int] {
        items.indices.filter { items[$0].type == .expense }
    }

    private var cleanedItems: [RecurringTemplateDraft] {
        items.filter {
            !$0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.amount > 0
        }
    }

    private var totalIncome: Double {
        cleanedItems
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        cleanedItems
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var projectedAmount: Double {
        totalIncome - totalExpense
    }

    private var canStart: Bool {
        !cleanedItems.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Incomes") {
                    if incomeIndices.isEmpty {
                        Text("Add your salary or any recurring income.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(incomeIndices, id: \.self) { index in
                            recurringItemRow(for: index)
                        }
                    }

                    Button {
                        items.append(
                            RecurringTemplateDraft(type: .income, label: "", amount: 0)
                        )
                    } label: {
                        Label("Add income", systemImage: "plus.circle")
                    }
                }

                Section("Expenses") {
                    if expenseIndices.isEmpty {
                        Text("Add your rent, insurance, subscriptions, etc.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(expenseIndices, id: \.self) { index in
                            recurringItemRow(for: index)
                        }
                    }

                    Button {
                        items.append(
                            RecurringTemplateDraft(type: .expense, label: "", amount: 0)
                        )
                    } label: {
                        Label("Add expense", systemImage: "minus.circle")
                    }
                }

                Section("Summary") {
                    summaryRow(title: "Total incomes", amount: totalIncome, style: .green)
                    summaryRow(title: "Total expenses", amount: totalExpense, style: .red)
                    summaryRow(title: "Base monthly amount", amount: projectedAmount, style: .primary)
                }
            }
            .navigationTitle("Welcome")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        onComplete(cleanedItems)
                    }
                    .disabled(!canStart)
                }
            }
        }
    }

    // MARK: - Components

    private func recurringItemRow(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                TextField("Label", text: $items[index].label)

                Button(role: .destructive) {
                    items.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            TextField(
                "Amount",
                value: $items[index].amount,
                format: .number.precision(.fractionLength(0...2))
            )
            .keyboardType(.decimalPad)
        }
        .padding(.vertical, 6)
    }

    private func summaryRow(title: String, amount: Double, style: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(CurrencyFormatting.formatCurrency(amount, code: currencyCode))
                .foregroundStyle(style)
                .bold()
        }
    }
}
