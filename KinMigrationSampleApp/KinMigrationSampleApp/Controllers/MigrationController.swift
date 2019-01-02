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
    func migrationController(_ controller: MigrationController, error: Error)
}

class MigrationController: NSObject {
    weak var delegate: MigrationControllerDelegate?

    private(set) var environment: Environment?
    private var migrationManager: KinMigrationManager?

    func startManager(with environment: Environment) {
        self.environment = environment

        guard let appId = try? AppId(network: environment.network) else {
            fatalError()
        }

        let migrationManager = KinMigrationManager(network: environment.network, appId: appId)
        migrationManager.delegate = self
        try? migrationManager.start(withVersionURL: .version(environment))
        self.migrationManager = migrationManager
    }
}

// MARK: - Kin Migration Manager

extension MigrationController: KinMigrationManagerDelegate {
    func kinMigrationManagerDidStart(_ kinMigrationManager: KinMigrationManager) {

    }

    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, didCreateClient client: KinClientProtocol) {
        delegate?.migrationController(self, didCreateClient: client)
    }

    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, error: Error) {
        if let viewController = UIApplication.shared.keyWindow?.rootViewController, viewController.presentedViewController == nil {
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
            viewController.present(alertController, animated: true)
        }

        delegate?.migrationController(self, error: error)
    }
}

// MARK: - Whitelist

extension MigrationController {
    static func whitelist(url: URL, networkId: String) -> WhitelistClosure {
        return { transactionEnvelope -> Promise<TransactionEnvelope> in
            let promise: Promise<TransactionEnvelope> = Promise()
            let whitelistEnvelope = WhitelistEnvelope(transactionEnvelope: transactionEnvelope, networkId: networkId)

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
