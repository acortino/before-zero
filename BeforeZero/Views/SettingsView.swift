//
//  SettingsView.swift
//  BeforeZero
//
//  Created by acortino on 14/02/2026.
//
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppCurrency.Keys.currency) private var currencyRaw: String = AppCurrency.eur.rawValue
    @AppStorage(AppTheme.Keys.theme) private var themeRaw: String = AppTheme.system.rawValue

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
    }
}
