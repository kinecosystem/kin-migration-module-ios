//
//  KinMigrationModuleHelper.swift
//  KinMigrationModuleTests
//
//  Created by Corey Werner on 23/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinMigrationModule

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
