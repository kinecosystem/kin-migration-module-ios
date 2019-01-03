//
//  KinMigrationManager.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import KinUtil

public protocol KinMigrationManagerDelegate: NSObjectProtocol {
    /**
     Asks the delegate for the Kin version to be used.

     The returned value is passed in a `Promise` allowing for the answer to be determined from a
     URL request. The migration process will only begin if `.kinSDK` is returned.

     - Parameter kinMigrationManager: The migration-manager object requesting this information.

     - Returns: A `Promise` of the `KinVersion` to be used.
     */
    func kinMigrationManagerNeedsVersion(_ kinMigrationManager: KinMigrationManager) -> Promise<KinVersion>

    /**
     Tells the delegate that the migration process has begun.

     The migration process will only start if the version is `.kinSDK`.

     - Parameter kinMigrationManager: The migration-manager object providing this information.
     */
    func kinMigrationManagerDidStart(_ kinMigrationManager: KinMigrationManager)

    /**
     Tells the delegate that the client is ready to be used.

     When the migration manager uses Kin Core, or when the accounts have successfully migrated
     to the Kin SDK, the client will be returned.

     - Parameter kinMigrationManager: The migration-manager object providing this information.
     - Parameter client: The client used to interact with Kin.
     */
    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, readyWith client: KinClientProtocol)

    /**
     Tells the delegate that the migration encountered an error.

     When an error is encountered, the migration process will be stopped.

     - Parameter kinMigrationManager: The migration-manager object providing this information.
     - Parameter error: The error which stopped the migration process.
     */
    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, error: Error)
}

public class KinMigrationManager {
    public weak var delegate: KinMigrationManagerDelegate?

    public let network: Network
    public let appId: AppId

    /**
     The node URL used for a `.custom` network.
     */
    public var nodeURL: URL?

    /**
     Initializes and returns a migration-manager object having the given network and appId.

     When a `.custom` network is used, the `nodeURL` must be set.

     - Parameter network: The `Network` which the client is connected to.
     - Parameter appId: The `AppId` attached to all transactions.
     */
    public init(network: Network, appId: AppId) {
        self.network = network
        self.appId = appId
    }

    fileprivate(set) var version: KinVersion?

    /**
     Tell the migration manager to start the process.

     - Throws: An error if the `delegate` was not set.
     */
    public func start() throws {
        guard delegate != nil else {
            throw KinMigrationError.missingDelegate
        }

        if isMigrated {
            version = .kinSDK
            delegateClientCreation()
        }
        else {
            requestVersion()
        }
    }

    fileprivate lazy var kinCoreClient: KinClientProtocol? = {
        return self.createClient(version: .kinCore)
    }()

    fileprivate lazy var kinSDKClient: KinClientProtocol? = {
        return self.createClient(version: .kinSDK)
    }()
}

// MARK: - State

extension KinMigrationManager {
    public fileprivate(set) var isMigrated: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "KinMigrationDidMigrateToKin3")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "KinMigrationDidMigrateToKin3")
        }
    }

    fileprivate func requestVersion() {
        delegate?.kinMigrationManagerNeedsVersion(self)
            .then { [weak self] version in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.version = version

                switch version {
                case .kinCore:
                    strongSelf.delegateClientCreation()
                case .kinSDK:
                    strongSelf.prepareBurning()
                }
        }
    }

    fileprivate func completed() {
        isMigrated = true
        delegateClientCreation()
    }
}

// MARK: - Client

extension KinMigrationManager {
    fileprivate func createClient(version: KinVersion) -> KinClientProtocol? {
        do {
            let factory = KinClientFactory(version: version)
            return try factory.KinClient(network: network, appId: appId, nodeURL: nodeURL)
        }
        catch {
            delegate?.kinMigrationManager(self, error: error)
            return nil
        }
    }

    fileprivate func delegateClientCreation() {
        guard let version = version else {
            return
        }

        var client: KinClientProtocol?

        switch version {
        case .kinCore:
            client = kinCoreClient
        case .kinSDK:
            client = kinSDKClient
        }

        if let client = client {
            delegate?.kinMigrationManager(self, readyWith: client)
        }
    }
}

// MARK: - Account

extension KinMigrationManager {
    fileprivate func prepareBurning() {
        delegate?.kinMigrationManagerDidStart(self)
        burnAccounts()
    }

    fileprivate func burnAccounts() {
        guard version == .kinSDK else {
            return
        }

        guard let client = kinCoreClient else {
            return
        }

        DispatchQueue.global(qos: .background).async {
            await(client.accounts.makeIterator().map { $0.burn() })
                .then { _ in
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }

                        strongSelf.migrateAccounts()
                    }
                }
                .error { error in
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }

                        strongSelf.delegate?.kinMigrationManager(strongSelf, error: error)
                    }
            }
        }
    }

    private func migrateAccount(_ account: KinAccountProtocol) -> Promise<Void> {
        let promise = Promise<Void>()

        var urlRequest = URLRequest(url: URL(string: "http://10.4.59.1:8000/migrate?address=\(account.publicAddress)")!)
        urlRequest.httpMethod = "POST"

        KinRequest(urlRequest).resume()
            .then { [weak self] response in
                guard let strongSelf = self else {
                    return
                }

                switch response.code {
                case KinRequest.MigrateCode.success.rawValue,
                     KinRequest.MigrateCode.accountAlreadyMigrated.rawValue:
                    if strongSelf.moveAccountToKinSDKIfNeeded(account) {
                        promise.signal(Void())
                    }
                default:
                    promise.signal(KinMigrationError.migrateFailed(code: response.code, message: response.message))
                }
            }
            .error { error in
                promise.signal(error)
        }

        return promise
    }

    fileprivate func migrateAccounts() {
        guard version == .kinSDK else {
            return
        }

        guard let client = kinCoreClient else {
            return
        }

        let promises = client.accounts.makeIterator().map({ migrateAccount($0) })

        DispatchQueue.global(qos: .background).async {
            await(promises)
                .then { _ in
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }

                        strongSelf.completed()
                    }
                }
                .error { error in
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }

                        strongSelf.delegate?.kinMigrationManager(strongSelf, error: error)
                    }
            }
        }
    }

    /**
     Move the Kin Core keychain account to the Kin SDK keychain.

     - Returns: True if there were no errors.
     */
    private func moveAccountToKinSDKIfNeeded(_ account: KinAccountProtocol) -> Bool {
        guard let kinSDKClient = kinSDKClient else {
            return false
        }

        let hasAccount = kinSDKClient.accounts.makeIterator().contains { kinSDKAccount -> Bool in
            return kinSDKAccount.publicAddress == account.publicAddress
        }

        guard hasAccount == false else {
            return true
        }

        do {
            let json = try account.export(passphrase: "")
            let _ = try kinSDKClient.importAccount(json, passphrase: "")

            return true
        }
        catch {
            delegate?.kinMigrationManager(self, error: error)
        }

        return false
    }
}
