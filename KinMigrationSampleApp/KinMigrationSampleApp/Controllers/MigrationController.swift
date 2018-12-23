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

    private(set) var environment: Environment?
    private var migrationManager: KinMigrationManager?

    func startManager(with environment: Environment) {
        self.environment = environment

        let migrationManager = KinMigrationManager()
        migrationManager.delegate = self
        try? migrationManager.start(withVersionURL: .version(environment))
        self.migrationManager = migrationManager
    }
}

// MARK: - Kin Migration Manager

extension MigrationController: KinMigrationManagerDelegate {
    func kinMigrationManagerCanCreateClient(_ kinMigrationManager: KinMigrationManager, factory: KinClientFactory) {
        guard let network = environment?.network else {
            return
        }

        guard let appId = try? AppId(network: network) else {
            return
        }

        let client = factory.KinClient(network: network, appId: appId)
        
        delegate?.migrationController(self, didCreateClient: client)
    }

    func kinMigrationManagerError(_ kinMigrationManager: KinMigrationManager, error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true)
    }
}

// MARK: - Whitelist

extension MigrationController {
    static func whitelist(url: URL, network: Network) -> WhitelistClosure {
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
