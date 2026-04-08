//
//  SettingsView.swift
//  BeforeZero
//
//  Created by acortino on 14/02/2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue
    @AppStorage(AppTheme.Keys.theme) private var themeRaw: String = AppTheme.system.rawValue

    @Query(sort: [
        SortDescriptor(\RecurringTemplateItem.sortOrder, order: .forward),
        SortDescriptor(\RecurringTemplateItem.createdAt, order: .forward)
    ])
    private var recurringTemplates: [RecurringTemplateItem]

    @State private var showEraseConfirmation = false
    @State private var showEraseSuccess = false
    @State private var errorMessage: String?

    private var currency: Binding<AppCurrency> {
        Binding(
            get: { AppCurrency(rawValue: currencyRaw) ?? .eur },
            set: { currencyRaw = $0.rawValue }
        )
    }

    private var theme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: themeRaw) ?? .system },
            set: { themeRaw = $0.rawValue }
        )
    }

    private var repository: BudgetRepository {
        BudgetRepository(context: modelContext)
    }

    private var baselineAmount: Double {
        recurringTemplates
            .filter { $0.isActive }
            .reduce(0) { partial, item in
                switch item.type {
                case .income:
                    return partial + item.amount
                case .expense:
                    return partial - item.amount
                }
            }
    }

    var body: some View {
        Form {
            Section("Preferences") {
                Picker("Currency", selection: currency) {
                    ForEach(AppCurrency.allCases) { currency in
                        Text("\(CurrencyFormatting.formatCurrency(1234.56, code: currency.code))  •  \(currency.code)")
                            .tag(currency)
                    }
                }

                Picker("Appearance", selection: theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
            }

            Section("Budget setup") {
                NavigationLink {
                    RecurringItemsEditorView()
                } label: {
                    HStack {
                        Text("Edit recurring incomes & expenses")
                        Spacer()
                        Text(
                            CurrencyFormatting.formatCurrency(
                                baselineAmount,
                                code: (AppCurrency(rawValue: currencyRaw) ?? .eur).code
                            )
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Data") {
                Button(role: .destructive) {
                    showEraseConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Erase all data")
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Warning")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)

                    Text("This permanently deletes your recurring template items and every archived month. This action cannot be undone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppInfo.versionString)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .overlay(alignment: .top) {
            if showEraseSuccess {
                Text("All data erased")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showEraseSuccess)
        .confirmationDialog(
            "Erase all app data?",
            isPresented: $showEraseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Erase all data", role: .destructive) {
                do {
                    try repository.eraseAllData()
                    showTemporarySuccessBanner()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove your recurring template items and all archived operations.")
        }
        .alert("Couldn’t Erase Data", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    private func showTemporarySuccessBanner() {
        showEraseSuccess = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showEraseSuccess = false
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
