//
//  MigrationController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 16/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinMigrationModule

protocol MigrationControllerDelegate: NSObjectProtocol {
    func migrationController(_ controller: MigrationController, didCreateClient client: KinClientProtocol)
}

class MigrationController: NSObject {
    weak var delegate: MigrationControllerDelegate?

    private(set) var network: Network?
    private var migrationManager: KinMigrationManager?

    func startManager(on network: Network) {
        self.network = network

        let migrationManager = KinMigrationManager()
        migrationManager.delegate = self
        try? migrationManager.start(withVersionURL: .version(network))
        self.migrationManager = migrationManager
    }
}

// MARK: - Kin Migration Manager

extension MigrationController: KinMigrationManagerDelegate {
    func kinMigrationManagerCanCreateClient(_ kinMigrationManager: KinMigrationManager, factory: KinClientFactory) {
        guard let network = network else {
            return
        }

        guard let appId = try? AppId(network: network) else {
            return
        }

        let client = factory.KinClient(with: .node(network), network: network, appId: appId)

        delegate?.migrationController(self, didCreateClient: client)

//        if let account = try? client.accounts.first ?? client.addAccount() {
//            let whitelist = self.whitelist(url: .whitelist(network), network: network)
//
//            account.sendTransaction(to: "", kin: 100, memo: nil, whitelist: whitelist)
//                .then { transactionId -> Void in
//
//            }
//        }
    }

    func kinMigrationManagerError(_ kinMigrationManager: KinMigrationManager, error: Error) {

    }
}

// MARK: - Whitelist

extension MigrationController {
    private func whitelist(url: URL, network: Network) -> WhitelistClosure {
        return { transactionEnvelope -> Promise<TransactionEnvelope> in
            let promise: Promise<TransactionEnvelope> = Promise()
            let whitelistEnvelope = WhitelistEnvelope(transactionEnvelope: transactionEnvelope, networkId: network.id)

            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = try? JSONEncoder().encode(whitelistEnvelope)

            URLSession.shared.dataTask(with: request) { (data, response, error) in
                do {
                    promise.signal(try TransactionEnvelope.decodeResponse(data: data, error: error))
                }
                catch {
                    promise.signal(error)
                }
                }.resume()

            return promise
        }
    }
}
