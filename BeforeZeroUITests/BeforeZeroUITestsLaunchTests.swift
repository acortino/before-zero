//
//  BeforeZeroUITestsLaunchTests.swift
//  BeforeZeroUITests
//
//  Created by acortino on 27/01/2026.
//

import XCTest
@testable import BeforeZero

final class BeforeZeroUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Ensure a clean UserDefaults sandbox for each test.
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)

        manager = ExpenseManager()
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    var manager: ExpenseManager!

    func testInitialSetup() {
        XCTAssertNil(manager.initialAmount)
        manager.setInitialAmount(100.0)
        XCTAssertEqual(manager.initialAmount, 100.0)
        XCTAssertEqual(manager.currentAmount, 100.0)
    }

    func testAddExpenseDecreasesTotal() {
        manager.setInitialAmount(200)
        manager.addExpense(45.5)
        XCTAssertEqual(manager.currentAmount, 154.5, accuracy: 0.001)
    }

    func testAddInputIncreasesTotal() {
        manager.setInitialAmount(80)
        manager.addInput(20)
        XCTAssertEqual(manager.currentAmount, 100, accuracy: 0.001)
    }

    func testResetRestoresInitial() {
        manager.setInitialAmount(150)
        manager.addExpense(30)
        manager.addInput(10)
        XCTAssertNotEqual(manager.currentAmount, 150)
        manager.resetToInitial()
        XCTAssertEqual(manager.currentAmount, 150)
    }

    func testPersistenceAcrossInstances() {
        manager.setInitialAmount(75)
        manager.addExpense(25)   // total now 50

        // Simulate app relaunch – create a fresh manager.
        let newManager = ExpenseManager()
        XCTAssertEqual(newManager.initialAmount, 75)
        XCTAssertEqual(newManager.currentAmount, 50, accuracy: 0.001)
    }
}
