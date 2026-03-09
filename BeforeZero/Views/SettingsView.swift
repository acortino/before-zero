//
//  SettingsView.swift
//  BeforeZero
//
//  Created by acortino on 14/02/2026.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    
    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue
    @AppStorage(AppTheme.Keys.theme) private var themeRaw: String = AppTheme.system.rawValue
    
    @State private var showEraseConfirmation = false
    @State private var showEraseSuccess = false
    
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

    var body: some View {
        Form {
            Section("Preferences") {
                Picker("Currency", selection: currency) {
                    ForEach(AppCurrency.allCases) { c in
                        Text("\(CurrencyFormatting.formatCurrency(1234.56, code: c.code))  •  \(c.code)")
                            .tag(c)
                    }
                }

                Picker("Appearance", selection: theme) {
                    ForEach(AppTheme.allCases) { t in
                        Text(t.label).tag(t)
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
                        Text(CurrencyFormatting.formatCurrency(expenseManager.initialAmount, code: (AppCurrency(rawValue: currencyRaw) ?? .eur).code))
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

                               Text("This permanently deletes your initial amount and all operations. This action cannot be undone.")
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
                expenseManager.eraseAllData()
                showTemporarySuccessBanner()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove your initial amount and all operations.")
        }
    }
    
    private func showTemporarySuccessBanner() {
        showEraseSuccess = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showEraseSuccess = false
        }
    }
}
#Preview {
    SettingsView()
        .environmentObject(ExpenseManager())
}
