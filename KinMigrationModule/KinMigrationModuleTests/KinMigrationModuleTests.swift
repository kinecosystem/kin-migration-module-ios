//
//  KinMigrationModuleTests.swift
//  KinMigrationModuleTests
//
//  Created by Corey Werner on 11/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import XCTest
@testable import KinMigrationModule

class KinMigrationModuleTests: XCTestCase {
    var migrationHelper: KinMigrationModuleHelper?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func kinCoreClient() -> Promise<KinClientProtocol> {
        let url = URL(string: "http://www.mocky.io/v2/5c18b4642f00005300af10e2")!
        let migrationHelper = KinMigrationModuleHelper(blockchainURL: url, promise: Promise<KinClientProtocol>())
        self.migrationHelper = migrationHelper
        return migrationHelper.promise
    }

    func kinSDKClient() -> Promise<KinClientProtocol> {
        let url = URL(string: "http://www.mocky.io/v2/5c18b46b2f00006500af10e4")!
        let migrationHelper = KinMigrationModuleHelper(blockchainURL: url, promise: Promise<KinClientProtocol>())
        self.migrationHelper = migrationHelper
        return migrationHelper.promise
    }

    func testCreateKinSDKClient() {
        let expectation = self.expectation(description: "Create Kin SDK Client")

        kinSDKClient()
            .then { kinClient in
                expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateKinSDKAccount() {
        let expectation = self.expectation(description: "Create Kin SDK Account")

        kinSDKClient()
            .then { kinClient in
                do {
                    _ = try kinClient.addAccount()
                    expectation.fulfill()
                }
                catch {
                    XCTFail(error.localizedDescription)
                }
            }

        wait(for: [expectation], timeout: 10)
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
