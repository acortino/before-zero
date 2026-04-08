//
//  RecurringItemsEditorView.swift
//  BeforeZero
//

import SwiftUI
import SwiftData

struct RecurringItemsEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [
        SortDescriptor(\RecurringTemplateItem.sortOrder, order: .forward),
        SortDescriptor(\RecurringTemplateItem.createdAt, order: .forward)
    ])
    private var recurringTemplates: [RecurringTemplateItem]

    @State private var draftItems: [RecurringTemplateDraft] = []
    @State private var errorMessage: String?

    private var currencyCode: String {
        (AppCurrency(rawValue: currencyRaw) ?? .eur).code
    }

    private var repository: BudgetRepository {
        BudgetRepository(context: modelContext)
    }

    private var incomeIndices: [Int] {
        draftItems.indices.filter { draftItems[$0].type == .income }
    }

    private var expenseIndices: [Int] {
        draftItems.indices.filter { draftItems[$0].type == .expense }
    }

    private var cleanedItems: [RecurringTemplateDraft] {
        draftItems.filter {
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

    var body: some View {
        Form {
            Section("Incomes") {
                if incomeIndices.isEmpty {
                    Text("No recurring incomes yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(incomeIndices, id: \.self) { index in
                        recurringItemEditor(for: index)
                    }
                }

                Button {
                    draftItems.append(
                        RecurringTemplateDraft(type: .income, label: "", amount: 0)
                    )
                } label: {
                    Label("Add income", systemImage: "plus.circle")
                }
            }

            Section("Expenses") {
                if expenseIndices.isEmpty {
                    Text("No recurring expenses yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(expenseIndices, id: \.self) { index in
                        recurringItemEditor(for: index)
                    }
                }

                Button {
                    draftItems.append(
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
        .navigationTitle("Recurring items")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    do {
                        try repository.replaceRecurringTemplateItems(cleanedItems)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .onAppear {
            if draftItems.isEmpty {
                draftItems = recurringTemplates.map(RecurringTemplateDraft.init(template:))
            }
        }
        .alert("Couldn’t Save Changes", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    private func recurringItemEditor(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                TextField("Label", text: $draftItems[index].label)

                Button(role: .destructive) {
                    draftItems.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            TextField(
                "Amount",
                value: $draftItems[index].amount,
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

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }
}
