//
//  Formatting.swift
//  BeforeZero
//
//  Created by acortino on 14/02/2026.
//

import Foundation

enum CurrencyFormatting {
    static func numberFormatter(locale: Locale = .current) -> NumberFormatter {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .decimal
        nf.usesGroupingSeparator = true
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        return nf
    }

    static func currencyFormatter(code: String, locale: Locale = .current) -> NumberFormatter {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .currency
        nf.currencyCode = code
        // Let the formatter decide fraction digits (JPY → 0, others → usually 2)
        nf.maximumFractionDigits = 20
        nf.minimumFractionDigits = 0
        return nf
    }

    static func formatCurrency(_ value: Double, code: String, locale: Locale = .current) -> String {
        currencyFormatter(code: code, locale: locale).string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Parses a user-entered string using the current locale decimal/grouping separators.
    static func parseUserNumber(_ text: String, locale: Locale = .current) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .decimal
        nf.usesGroupingSeparator = true
        nf.maximumFractionDigits = 20

        return nf.number(from: trimmed)?.doubleValue
    }
}

