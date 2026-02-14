//
//  BeforeZeroApp.swift
//  BeforeZero
//
//  Created by acortino on 27/01/2026.
//


import SwiftUI
import SwiftData

@main
struct BeforeZeroApp: App {
    @EnvironmentObject var manager: ExpenseManager
    @AppStorage(AppTheme.Keys.theme) private var themeRaw: String = AppTheme.system.rawValue

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([

        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Homepage()
                .preferredColorScheme((AppTheme(rawValue: themeRaw) ?? .system).preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
