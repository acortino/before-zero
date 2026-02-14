//
//  AppSettings.swift
//  BeforeZero
//
//  Created by acortino on 14/02/2026.
//

import SwiftUI

enum AppCurrency: String, CaseIterable, Identifiable {
    case eur, usd, gbp, chf, jpy

    var id: String { rawValue }

    var code: String {
        switch self {
        case .eur: return "EUR"
        case .usd: return "USD"
        case .gbp: return "GBP"
        case .chf: return "CHF"
        case .jpy: return "JPY"
        }
    }

    var symbol: String {
        switch self {
        case .eur: return "€"
        case .usd: return "$"
        case .gbp: return "£"
        case .chf: return "CHF"
        case .jpy: return "¥"
        }
    }

    static var selected: AppCurrency {
        let raw = UserDefaults.standard.string(forKey: Keys.currency) ?? AppCurrency.eur.rawValue
        return AppCurrency(rawValue: raw) ?? .eur
    }

    enum Keys {
        static let currency = "app_currency"
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    static var selected: AppTheme {
        let raw = UserDefaults.standard.string(forKey: Keys.theme) ?? AppTheme.system.rawValue
        return AppTheme(rawValue: raw) ?? .system
    }

    enum Keys {
        static let theme = "app_theme"
    }
}

struct AppInfo {
    static var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }
}
