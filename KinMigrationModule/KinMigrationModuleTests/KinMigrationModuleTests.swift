//
//  KinMigrationModuleTests.swift
//  KinMigrationModuleTests
//
//  Created by Corey Werner on 11/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import XCTest
@testable import KinMigrationModule

class KinMigrationModuleHelper: NSObject {
    let migrationManager = KinMigrationManager()
    let network: Network
    let appIdValue: String
    let promise: Promise<KinClientProtocol>

    init(blockchainURL: URL, network: Network = .testNet, appIdValue: String = "test", promise: Promise<KinClientProtocol>) {
        self.network = network
        self.appIdValue = appIdValue
        self.promise = promise

        super.init()

        migrationManager.delegate = self

        do {
            try migrationManager.start(withVersionURL: blockchainURL)
        }
        catch {
            promise.signal(error)
        }
    }
}

extension KinMigrationModuleHelper: KinMigrationManagerDelegate {
    func kinMigrationManagerCanCreateClient(_ kinMigrationManager: KinMigrationManager, factory: KinClientFactory) {
        do {
            let appId = try AppId(appIdValue)
            let client = factory.KinClient(network: network, appId: appId)
            promise.signal(client)
        }
        catch {
            promise.signal(error)
        }
    }

    func kinMigrationManagerError(_ kinMigrationManager: KinMigrationManager, error: Error) {
        promise.signal(error)
    }
}

class KinMigrationModuleTests: XCTestCase {
    let kinCoreBlockchainURL = URL(string: "http://www.mocky.io/v2/5c18b4642f00005300af10e2")!
    let kinSDKBlockchainURL = URL(string: "http://www.mocky.io/v2/5c18b46b2f00006500af10e4")!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func kinCoreClient() -> Promise<KinClientProtocol> {
        let migrationHelper = KinMigrationModuleHelper(blockchainURL: kinCoreBlockchainURL, promise: Promise<KinClientProtocol>())
        return migrationHelper.promise
    }

    func kinSDKClient() -> Promise<KinClientProtocol> {
        let migrationHelper = KinMigrationModuleHelper(blockchainURL: kinSDKBlockchainURL, promise: Promise<KinClientProtocol>())
        return migrationHelper.promise
    }

    func testExample() {
        let expectation = self.expectation(description: "Create Kin Client")

        kinSDKClient()
            .then { kinClient in
                XCTAssertNotNil(kinClient)
                expectation.fulfill()
            }
            .error { error in
                XCTFail()
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
