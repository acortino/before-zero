//
//  BeforeZeroUITestsLaunchTests.swift
//  BeforeZeroUITests
//
//  Created by acortino on 27/01/2026.
//

import XCTest

final class BeforeZeroUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
