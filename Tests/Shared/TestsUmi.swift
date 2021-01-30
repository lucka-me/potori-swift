//
//  TestsUmi.swift
//  Tests macOS
//
//  Created by Lucka on 23/1/2021.
//

import XCTest

class TestsUmi: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitPerformance() throws {
        self.measure(metrics: [ XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric() ]) {
            let _ = Umi.unitTestInit()
        }
    }

    func testStatus() throws {
        XCTAssertEqual(Umi.unitTestShared.status.count, 3)
        XCTAssertNotNil(Umi.unitTestShared.status[.pending])
        XCTAssertNotNil(Umi.unitTestShared.status[.accepted])
        XCTAssertNotNil(Umi.unitTestShared.status[.rejected])
    }
    
    func testScanner() throws {
        XCTAssertNotNil(Umi.unitTestShared.scanner[.unknown])
        XCTAssertNotNil(Umi.unitTestShared.scanner[.redacted])
        XCTAssertNotNil(Umi.unitTestShared.scanner[.prime])
    }
    
    func testReason() throws {
        XCTAssertNotNil(Umi.unitTestShared.reason[Umi.Reason.undeclared])
    }
}
