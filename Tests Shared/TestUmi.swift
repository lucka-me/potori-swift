//
//  TestUmi.swift
//  Tests macOS
//
//  Created by Lucka on 23/1/2021.
//

import XCTest

class TestUmi: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitPerformance() throws {
        // This is an example of a performance test case.
        self.measure(metrics: [XCTClockMetric()]) {
            // Put the code you want to measure the time of here.
            let _ = Umi.unitTestInit()
        }
    }

    func testStatus() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(Umi.unitTestShared.status.count, 3)
        XCTAssertNotNil(Umi.unitTestShared.status[.pending])
        XCTAssertNotNil(Umi.unitTestShared.status[.accepted])
        XCTAssertNotNil(Umi.unitTestShared.status[.rejected])
    }
}
