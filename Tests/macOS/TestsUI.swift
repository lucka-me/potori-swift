//
//  Tests_macOS.swift
//  Tests macOS
//
//  Created by Lucka on 23/1/2021.
//

import XCTest

class TestsUI: XCTestCase {
    
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        app.launchArguments = [ "-AppleLanguages", "(en)" ]
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testNavigation() throws {
        app.activate()
        app.outlines.buttons["List"].click()
        app.outlines.buttons["Map"].click()
        app.outlines.buttons["Dashboard"].click()
    }
}
