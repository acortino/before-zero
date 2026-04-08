//
//  MonthDetailsView.swift
//  BeforeZero
//
//  Created by acortino on 06/04/2026.
//

import SwiftUI
import SwiftData

struct MonthDetailsView: View {
    private struct MonthSnapshot {
        let title: String
        let baselineAmount: Double
    }

    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue
    @Environment(\.modelContext) private var modelContext
    
    let monthKey: Int
    
    @State private var monthSnapshot: MonthSnapshot?
    @State private var operations: [BudgetOperation] = []
    @State private var balanceLookup: [UUID: Double] = [:]
    
    @State private var selectedFilter: BudgetOperationFilter = .all
    @State private var selectedSort: BudgetOperationSort = .dateDescending
    @State private var editingOperation: BudgetOperation?
    @State private var errorMessage: String?
    
    init(monthKey: Int) {
        self.monthKey = monthKey
    }
    
    private var currencyCode: String {
        (AppCurrency(rawValue: currencyRaw) ?? .eur).code
    }
    
    private var repository: BudgetRepository {
        BudgetRepository(context: modelContext)
    }
    
    private var currentAmount: Double {
        guard let monthSnapshot else { return 0 }
        return repository.currentAmount(
            baselineAmount: monthSnapshot.baselineAmount,
            operations: operations
        )
    }
    
    var body: some View {
        Group {
            if let monthSnapshot {
                List {
                    summarySection(monthSnapshot: monthSnapshot)
                    controlsSection
                    operationsSection
                }
                .navigationTitle(monthSnapshot.title)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView(
                    "Month not found",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("This month could not be loaded.")
                )
                .navigationTitle("Month")
            }
        }
        .onAppear {
            loadMonthDetails()
        }
        .onChange(of: selectedFilter) { _, _ in
            do {
                try reloadOperations()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .onChange(of: selectedSort) { _, _ in
            do {
                try reloadOperations()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .sheet(item: $editingOperation) { operation in
            AmountEntryView(
                mode: operation.type == .expense ? .expense : .input,
                existingOperation: operation
            ) { result in
                guard let (amount, label) = result else { return }
                
                do {
                    try repository.updateOperation(
                        operation,
                        amount: amount,
                        label: label,
                        date: operation.date
                    )
                    try reloadOperations()
                } catch {
                    errorMessage = error.localizedDescription
                }
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
    
    private func loadMonthDetails() {
        do {
            if let month = try repository.month(monthKey: monthKey) {
                monthSnapshot = MonthSnapshot(
                    title: month.displayTitle,
                    baselineAmount: month.baselineAmount
                )
                try reloadOperations()
            } else {
                monthSnapshot = nil
                operations = []
                balanceLookup = [:]
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func reloadOperations() throws {
        guard monthSnapshot != nil else {
            operations = []
            balanceLookup = [:]
            return
        }

        operations = try repository.operations(
            forMonthKey: monthKey,
            filter: selectedFilter,
            sort: selectedSort
        )
        rebuildBalances()
    }
    
    private func rebuildBalances() {
        guard let monthSnapshot else {
            balanceLookup = [:]
            return
        }

        let balances = repository.runningBalances(
            baselineAmount: monthSnapshot.baselineAmount,
            operations: operations
        )
        balanceLookup = Dictionary(
            uniqueKeysWithValues: balances.map { ($0.operation.id, $0.balanceAfter) }
        )
    }
    
    private func summarySection(monthSnapshot: MonthSnapshot) -> some View {
        Section {
            HStack {
                Text("Base amount")
                Spacer()
                Text(CurrencyFormatting.formatCurrency(monthSnapshot.baselineAmount, code: currencyCode))
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Current amount")
                Spacer()
                Text(CurrencyFormatting.formatCurrency(currentAmount, code: currencyCode))
                    .bold()
            }
            
            HStack {
                Text("Operation count")
                Spacer()
                Text("\(operations.count)")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var controlsSection: some View {
        Section {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(BudgetOperationFilter.allCases) { filter in
                    Text(filter.label).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            
            Picker("Sort", selection: $selectedSort) {
                ForEach(BudgetOperationSort.allCases) { sort in
                    Text(sort.label).tag(sort)
                }
            }
        }
    }
    
    private var operationsSection: some View {
        Section("Operations") {
            if operations.isEmpty {
                Text("No operations yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(operations) { operation in
                    operationDetailRow(operation)
                }
            }
        }
    }
    
    private func operationDetailRow(_ operation: BudgetOperation) -> some View {
        let signedAmountText = signedAmountString(for: operation)
        let balanceAfter = balanceLookup[operation.id]
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(operation.label)
                        .font(.headline)
                    
                    Text(operation.date, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(signedAmountText)
                    .fontWeight(.semibold)
                    .foregroundStyle(operation.type == .expense ? .red : .green)
            }
            
            if let balanceAfter {
                Text("Balance after: \(CurrencyFormatting.formatCurrency(balanceAfter, code: currencyCode))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                do {
                    try repository.deleteOperation(operation)
                    try reloadOperations()
                } catch {
                    errorMessage = error.localizedDescription
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                editingOperation = operation
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
    
    private func signedAmountString(for operation: BudgetOperation) -> String {
        let formatted = CurrencyFormatting.formatCurrency(operation.amount, code: currencyCode)
        switch operation.type {
        case .expense:
            return "-\(formatted)"
        case .input:
            return "+\(formatted)"
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
