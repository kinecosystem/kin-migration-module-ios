//
//  MigrationController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 16/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinMigrationModule

protocol MigrationControllerDelegate: NSObjectProtocol {
    func migrationController(_ controller: MigrationController, readyWith client: KinClientProtocol)
    func migrationController(_ controller: MigrationController, error: Error)
}

class MigrationController: NSObject {
    weak var delegate: MigrationControllerDelegate?

    private(set) var environment: Environment?
    private var migrationManager: KinMigrationManager?

    func client(for environment: Environment) -> KinClientProtocol {
        self.environment = environment

        let migrateURL: URL? = environment.blockchain == .stellar ? .migrate(environment) : nil

        guard let serviceProvider = try? ServiceProvider(network: environment.network, migrateBaseURL: migrateURL) else {
            fatalError()
        }

        guard let appId = try? AppId(network: environment.network) else {
            fatalError()
        }

        let migrationManager = KinMigrationManager(serviceProvider: serviceProvider, appId: appId)
        migrationManager.delegate = self
        self.migrationManager = migrationManager

        switch environment {
        case .testKinCore, .mainKinCore:
            return migrationManager.kinClient(version: .kinCore)
        case .testKinSDK, .mainKinSDK:
            return migrationManager.kinClient(version: .kinSDK)
        }
    }

    func isAccountMigrated(publicAddress: String) -> Bool {
        return migrationManager?.isAccountMigrated(publicAddress: publicAddress) ?? false
    }

    func migrateAccount(with publicAddress: String) throws {
        try migrationManager?.start(with: publicAddress)
    }

    var version: KinVersion? {
        return migrationManager?.version
    }
}

// MARK: - Kin Migration Manager

extension MigrationController: KinMigrationManagerDelegate {
    private struct VersionResponse: Codable {
        let version: KinVersion
    }

    func kinMigrationManagerNeedsVersion(_ kinMigrationManager: KinMigrationManager) -> Promise<KinVersion> {
        guard let environment = environment else {
            fatalError()
        }

        let promise: Promise<KinVersion> = Promise()

        URLSession.shared.dataTask(with: .version(environment)) { (data, _, error) in
            if let error = error {
                promise.signal(error)
            }

            guard let data = data else {
                fatalError()
            }

            do {
                let response = try JSONDecoder().decode(VersionResponse.self, from: data)
                promise.signal(response.version)
            }
            catch {
                promise.signal(error)
            }
        }.resume()

        return promise
    }

    func kinMigrationManagerDidStart(_ kinMigrationManager: KinMigrationManager) {

    }

    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, readyWith client: KinClientProtocol) {
        delegate?.migrationController(self, readyWith: client)
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
        return { transactionEnvelope -> Promise<TransactionEnvelope?> in
            let promise: Promise<TransactionEnvelope?> = Promise()
            let whitelistEnvelope = WhitelistEnvelope(transactionEnvelope: transactionEnvelope, networkId: networkId)

            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = try? JSONEncoder().encode(whitelistEnvelope)

            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    promise.signal(error)
                    return
                }

                guard let data = data else {
                    promise.signal(KinMigrationError.unexpectedCondition)
                    return
                }

                do {
                    promise.signal(try XDRDecoder.decode(TransactionEnvelope.self, data: data))
                }
                catch {
                    promise.signal(error)
                }
            }.resume()

            return promise
        }
    }
}
