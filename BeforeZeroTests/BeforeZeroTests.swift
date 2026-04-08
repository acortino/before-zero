//
//  BeforeZeroTests.swift
//  BeforeZeroTests
//
//  Created by acortino on 27/01/2026.
//

import Foundation
import SwiftData
import Testing
@testable import BeforeZero

struct BeforeZeroTests {

    @MainActor
    @Test
    func currentMonthSnapshotsRecurringTemplates() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let repository = BudgetRepository(context: context, calendar: testCalendar)

        try repository.replaceRecurringTemplateItems([
            RecurringTemplateDraft(type: .income, label: "Salary", amount: 3000),
            RecurringTemplateDraft(type: .expense, label: "Rent", amount: 1200)
        ])

        let april = try repository.createMonthIfNeeded(for: makeDate(year: 2026, month: 4, day: 1))
        #expect(april.baselineAmount == 1800)

        try repository.replaceRecurringTemplateItems([
            RecurringTemplateDraft(type: .income, label: "Salary", amount: 4000),
            RecurringTemplateDraft(type: .expense, label: "Rent", amount: 1500)
        ])

        let may = try repository.createMonthIfNeeded(for: makeDate(year: 2026, month: 5, day: 1))
        #expect(april.baselineAmount == 1800)
        #expect(may.baselineAmount == 2500)
    }

    @MainActor
    @Test
    func currentAmountUsesBaselineAndSignedOperations() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let repository = BudgetRepository(context: context, calendar: testCalendar)

        try repository.replaceRecurringTemplateItems([
            RecurringTemplateDraft(type: .income, label: "Salary", amount: 2000),
            RecurringTemplateDraft(type: .expense, label: "Rent", amount: 900)
        ])

        let month = try repository.createMonthIfNeeded(for: makeDate(year: 2026, month: 4, day: 1))
        try repository.addOperation(to: month, type: .expense, amount: 100, label: "Groceries", date: makeDate(year: 2026, month: 4, day: 3))
        try repository.addOperation(to: month, type: .input, amount: 50, label: "Refund", date: makeDate(year: 2026, month: 4, day: 4))

        #expect(repository.currentAmount(for: month) == 1050)
        #expect(repository.totals(for: month).inputs == 50)
        #expect(repository.totals(for: month).expenses == 100)
    }

    @MainActor
    @Test
    func completeInitialSetupRepairsAnEmptyZeroBaselineCurrentMonth() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let repository = BudgetRepository(context: context, calendar: testCalendar)

        let date = makeDate(year: 2026, month: 4, day: 1)
        let emptyMonth = try repository.createMonthIfNeeded(for: date)
        #expect(emptyMonth.baselineAmount == 0)
        #expect(emptyMonth.operations.isEmpty)

        let repairedMonth = try repository.completeInitialSetup(
            with: [
                RecurringTemplateDraft(type: .income, label: "Salary", amount: 3000),
                RecurringTemplateDraft(type: .expense, label: "Rent", amount: 1000),
                RecurringTemplateDraft(type: .expense, label: "Insurance", amount: 200)
            ],
            for: date
        )

        #expect(repairedMonth.id == emptyMonth.id)
        #expect(repairedMonth.baselineAmount == 1800)
        #expect(try repository.baselineForNewMonth() == 1800)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            RecurringTemplateItem.self,
            BudgetMonth.self,
            BudgetOperation.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        return calendar
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(
            calendar: testCalendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day
        )
        return components.date ?? .now
    }
}
