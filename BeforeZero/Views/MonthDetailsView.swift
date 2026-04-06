//
//  MonthDetailsView.swift
//  BeforeZero
//
//  Created by acortino on 06/04/2026.
//

import SwiftUI

private enum OperationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case expense = "Expenses"
    case input = "Inputs"

    var id: String { rawValue }
}

private enum OperationSort: String, CaseIterable, Identifiable {
    case date = "Date"
    case label = "Label"
    case amount = "Amount"

    var id: String { rawValue }
}

private struct OperationDetailRow: Identifiable {
    let id: UUID
    let operation: Operation
}

struct MonthDetailsView: View {
    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue
    @EnvironmentObject var manager: ExpenseManager

    @State private var selectedFilter: OperationFilter = .all
    @State private var selectedSort: OperationSort = .date

    private var currencyCode: String {
        (AppCurrency(rawValue: currencyRaw) ?? .eur).code
    }

    /// Running total after each operation, computed chronologically.
    private var detailedOperations: [OperationDetailRow] {
        let chronological = manager.operations.sorted { $0.date < $1.date }

        var rows: [OperationDetailRow] = []

        for op in chronological {
            rows.append(
                OperationDetailRow(
                    id: op.id,
                    operation: op
                )
            )
        }

        return rows
    }

    private var filteredAndSortedRows: [OperationDetailRow] {
        let filtered = detailedOperations.filter { row in
            switch selectedFilter {
            case .all:
                return true
            case .expense:
                return row.operation.type == .expense
            case .input:
                return row.operation.type == .input
            }
        }

        switch selectedSort {
        case .date:
            return filtered.sorted { $0.operation.date > $1.operation.date } // newest first
        case .label:
            return filtered.sorted {
                $0.operation.label.localizedCaseInsensitiveCompare($1.operation.label) == .orderedAscending
            }
        case .amount:
            return filtered.sorted { $0.operation.amount > $1.operation.amount }
        }
    }

    var body: some View {
        List {
            summarySection
            controlsSection
            operationsSection
        }
        .navigationTitle("Current month")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summarySection: some View {
        Section {
            HStack {
                Text("Base amount")
                Spacer()
                Text(CurrencyFormatting.formatCurrency(manager.initialAmount, code: currencyCode))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Current amount")
                Spacer()
                Text(CurrencyFormatting.formatCurrency(manager.currentAmount, code: currencyCode))
                    .bold()
            }
        }
    }

    private var controlsSection: some View {
        Section {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(OperationFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Picker("Sort", selection: $selectedSort) {
                ForEach(OperationSort.allCases) { sort in
                    Text(sort.rawValue).tag(sort)
                }
            }
        }
    }

    private var operationsSection: some View {
        Section("Operations") {
            if filteredAndSortedRows.isEmpty {
                Text("No operations yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredAndSortedRows) { row in
                    operationDetailRow(row)
                }
            }
        }
    }

    private func operationDetailRow(_ row: OperationDetailRow) -> some View {
        let op = row.operation
        let signedAmountText = signedAmountString(for: op)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(op.label)
                        .font(.headline)

                    Text(op.date, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(signedAmountText)
                    .fontWeight(.semibold)
                    .foregroundStyle(op.type == .expense ? .red : .green)
            }

        }
        .padding(.vertical, 6)
    }

    private func signedAmountString(for op: Operation) -> String {
        let formatted = CurrencyFormatting.formatCurrency(op.amount, code: currencyCode)
        switch op.type {
        case .expense:
            return "-\(formatted)"
        case .input:
            return "+\(formatted)"
        }
    }
}
