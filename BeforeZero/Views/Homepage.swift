//
//  Homepage.swift
//  BeforeZero
//
//  Created by acortino on 27/01/2026.
//

import SwiftUI
import SwiftData

enum EntryMode {
    case expense
    case input
}

struct Homepage: View {
    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: [
        SortDescriptor(\RecurringTemplateItem.sortOrder, order: .forward),
        SortDescriptor(\RecurringTemplateItem.createdAt, order: .forward)
    ])
    private var recurringTemplates: [RecurringTemplateItem]

    @Query(sort: [
        SortDescriptor(\BudgetMonth.yearMonthKey, order: .reverse)
    ])
    private var months: [BudgetMonth]

    @State private var showingEntrySheet = false
    @State private var entryMode: EntryMode = .expense
    @State private var showCalculationInfo = false
    @State private var errorMessage: String?
    @State private var showOnboarding = false
    @State private var currentOperations: [BudgetOperation] = []
    @State private var path: [AppRoute] = []

    private var currencyCode: String {
        (AppCurrency(rawValue: currencyRaw) ?? .eur).code
    }

    private var repository: BudgetRepository {
        BudgetRepository(context: modelContext)
    }

    private var activeTemplateCount: Int {
        recurringTemplates.filter { $0.isActive }.count
    }

    private var currentMonthKey: Int {
        Calendar.autoupdatingCurrent.budgetMonthKey(for: .now)
    }

    private var currentMonth: BudgetMonth? {
        months.first { $0.yearMonthKey == currentMonthKey }
    }

    private func reloadCurrentOperations() {
        guard let currentMonth else {
            currentOperations = []
            return
        }

        do {
            currentOperations = try repository.operations(
                forMonthKey: currentMonth.yearMonthKey,
                filter: .all,
                sort: .dateDescending
            )
        } catch {
            errorMessage = error.localizedDescription
            currentOperations = []
        }
    }

    private var lastFiveOperations: [BudgetOperation] {
        Array(currentOperations.prefix(5))
    }

    private var baselineAmount: Double {
        currentMonth?.baselineAmount ?? 0
    }

    private var currentAmount: Double {
        guard let currentMonth else { return 0 }
        return repository.currentAmount(
            baselineAmount: currentMonth.baselineAmount,
            operations: currentOperations
        )
    }

    private var totalManualInputs: Double {
        currentOperations
            .filter { $0.type == .input }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalManualExpenses: Double {
        currentOperations
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var calculationExplanation: String {
        """
        Current amount = Base monthly amount + Manual inputs - Manual expenses

        Base monthly amount: \(CurrencyFormatting.formatCurrency(baselineAmount, code: currencyCode))
        Manual inputs: \(CurrencyFormatting.formatCurrency(totalManualInputs, code: currencyCode))
        Manual expenses: \(CurrencyFormatting.formatCurrency(totalManualExpenses, code: currencyCode))
        Current amount: \(CurrencyFormatting.formatCurrency(currentAmount, code: currencyCode))
        """
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("BeforeZero")
                .toolbar { settingsToolbar }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .archive:
                        MonthArchiveView()
                    case .year(let year):
                        YearMonthsView(year: year)
                    case .month(let key):
                        MonthDetailsView(monthKey: key)
                    case .settings:
                        SettingsView()
                    }
                }
                .padding()
        }
        .sheet(isPresented: $showingEntrySheet) { entrySheet }
        .fullScreenCover(isPresented: $showOnboarding) { onboardingView }
        .task {
            refreshBudgetState()
        }
        .onChange(of: activeTemplateCount) { _, _ in
            refreshBudgetState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshBudgetState()
            }
        }
        .alert("Calculation details", isPresented: $showCalculationInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(calculationExplanation)
        }
        .alert("Couldn’t Save Changes", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }
    
    private var content: some View {
        VStack(spacing: 24) {
            header
            actionButtons
            recentActivity
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Group {
                    if let currentMonth {
                        NavigationLink {
                            MonthDetailsView(monthKey: currentMonth.yearMonthKey)
                        } label: {
                            amountHeader
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        amountHeader
                    }
                }
                .buttonStyle(.plain)

                if currentMonth != nil {
                    Button {
                        showCalculationInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            GeometryReader { geo in
                let progress = max(0, min(currentAmount / max(baselineAmount, 1), 1))

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

    private var amountHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(CurrencyFormatting.formatCurrency(currentAmount, code: currencyCode))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("/")
                .foregroundStyle(.secondary)

            Text(CurrencyFormatting.formatCurrency(baselineAmount, code: currencyCode))
                .font(.title3)
                .foregroundStyle(.secondary)
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
            .disabled(currentMonth == nil)

            Button {
                entryMode = .input
                showingEntrySheet = true
            } label: {
                Label("Add input", systemImage: "plus.circle")
            }
            .disabled(currentMonth == nil)
        }
        .buttonStyle(.borderedProminent)
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(currentMonth?.displayTitle ?? "Current month")
                .font(.headline)

            if lastFiveOperations.isEmpty {
                Text("No operations yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(lastFiveOperations) { operation in
                    operationRow(operation)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func operationRow(_ operation: BudgetOperation) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(operation.label)
                Text(operation.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(signedAmountString(for: operation))
                .foregroundStyle(operation.type == .expense ? .red : .green)
        }
        .padding(.vertical, 6)
    }

    private var settingsToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            NavigationLink(value: AppRoute.archive) {
                Image(systemName: "calendar")
            }
            .accessibilityLabel("Browse months")

            NavigationLink(value: AppRoute.settings) {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }

    private var entrySheet: some View {
        AmountEntryView(mode: entryMode) { result in
            guard let currentMonth, let (amount, label) = result else { return }

            do {
                try repository.addOperation(
                    to: currentMonth,
                    type: entryMode == .expense ? .expense : .input,
                    amount: amount,
                    label: label,
                    date: .now
                )
                reloadCurrentOperations()
                showingEntrySheet = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var onboardingView: some View {
        FirstRunSetupView { items in
            do {
                _ = try repository.completeInitialSetup(with: items, for: .now)
                reloadCurrentOperations()
                showOnboarding = false
            } catch {
                errorMessage = error.localizedDescription
            }
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

    private func refreshBudgetState() {
        do {
            let hasActiveTemplates = try repository.hasActiveRecurringTemplateItems()
            showOnboarding = !hasActiveTemplates
            guard hasActiveTemplates else {
                currentOperations = []
                return
            }

            _ = try repository.createMonthIfNeeded(for: .now)
            reloadCurrentOperations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func signedAmountString(for operation: BudgetOperation) -> String {
        let formatted = CurrencyFormatting.formatCurrency(operation.amount, code: currencyCode)
        return operation.type == .expense ? "-\(formatted)" : "+\(formatted)"
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
        .modelContainer(for: [
            RecurringTemplateItem.self,
            BudgetMonth.self,
            BudgetOperation.self
        ], inMemory: true)
}
