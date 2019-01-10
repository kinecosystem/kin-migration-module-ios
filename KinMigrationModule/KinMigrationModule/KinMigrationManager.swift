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

    public let kinCoreServiceProvider: ServiceProviderProtocol
    public let kinSDKServiceProvider: ServiceProviderProtocol
    public let appId: AppId

    /**
     Initializes and returns a migration-manager object having the given service providers and
     appId.

     When the `version` is set to `.kinCore`, the `kinSDKServiceProvider` will not be called.
     However, when the `version` is set to `.kinSDK`, the `kinCoreServiceProvider` will be
     called for preparing the migration.

     - Important: The URL for migrating an account must be set on the `migrateBaseURL` property
     of the `kinSDKServiceProvider`.

     - Parameter kinCoreServiceProvider: The service provider for connecting to Kin Core.
     - Parameter kinSDKServiceProvider: The service provider for connecting to Kin SDK.
     - Parameter appId: The `AppId` attached to all transactions.
     */
    public init(kinCoreServiceProvider: ServiceProviderProtocol, kinSDKServiceProvider: ServiceProviderProtocol, appId: AppId) {
        self.kinCoreServiceProvider = kinCoreServiceProvider
        self.kinSDKServiceProvider = kinSDKServiceProvider
        self.appId = appId
    }

    fileprivate(set) public var version: KinVersion?

    /**
     Tell the migration manager to start the process.

     - Throws: An error if the `delegate` was not set.
     */
    public func start() throws {
        guard delegate != nil else {
            throw KinMigrationError.missingDelegate
        }

//        if isMigrated {
//            version = .kinSDK
//            delegateClientCreation()
//        }
//        else {
            requestVersion()
//        }
    }

    fileprivate lazy var kinCoreClient: KinClientProtocol = {
        return self.createClient(version: .kinCore)
    }()

    fileprivate lazy var kinSDKClient: KinClientProtocol = {
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
            .then(on: .main, { version in
                self.version = version

                switch version {
                case .kinCore:
                    self.delegateClientCreation()
                case .kinSDK:
                    self.prepareBurning()
                }
            })
    }

    fileprivate func completed() {
        isMigrated = true
        delegateClientCreation()
    }
}

// MARK: - Client

extension KinMigrationManager {
    fileprivate func createClient(version: KinVersion) -> KinClientProtocol {
        let serviceProvider: ServiceProviderProtocol

        switch version {
        case .kinCore:
            serviceProvider = kinCoreServiceProvider
        case .kinSDK:
            serviceProvider = kinSDKServiceProvider
        }

        let factory = KinClientFactory(version: version)
        return factory.KinClient(serviceProvider: serviceProvider, appId: appId)
    }

    fileprivate func delegateClientCreation() {
        guard let version = version else {
            delegate?.kinMigrationManager(self, error: KinMigrationError.unexpectedCondition)
            return
        }

        let client: KinClientProtocol

        switch version {
        case .kinCore:
            client = kinCoreClient
        case .kinSDK:
            client = kinSDKClient
        }

        delegate?.kinMigrationManager(self, readyWith: client)
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
            delegate?.kinMigrationManager(self, error: KinMigrationError.unexpectedCondition)
            return
        }

        let promises = kinCoreClient.accounts.makeIterator().map { kinAccount -> Promise<String?> in
            let promise = Promise<String?>()

            kinAccount.burn()
                .then { transactionHash in
                    promise.signal(transactionHash)
                }
                .error { error in
                    if case KinError.missingAccount = error {
                        promise.signal(nil)
                    }
                    else {
                        promise.signal(error)
                    }
                }

            return promise
        }

        DispatchQueue.global(qos: .background).async {
            await(promises)
                .then { _ in
                    DispatchQueue.main.async {
                        self.migrateAccounts()
                    }
                }
                .error { error in
                    DispatchQueue.main.async {
                        self.delegate?.kinMigrationManager(self, error: error)
                    }
            }
        }
    }

    private func needsToMigrateAccount(_ account: KinAccountProtocol) -> Promise<Bool> {
        return account.status().then(on: .main, { accountStatus -> Promise<Bool> in
            return Promise(accountStatus == .created)
        })
    }

    private func migrateAccount(_ account: KinAccountProtocol) -> Promise<Void> {
        let url: URL

        do {
            url = try kinSDKServiceProvider.migrateURL(publicAddress: account.publicAddress)
        }
        catch {
            return Promise(error)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        return KinRequest(urlRequest).resume()
            .then { response in
                switch response.code {
                case KinRequest.MigrateCode.success.rawValue,
                     KinRequest.MigrateCode.accountAlreadyMigrated.rawValue:
                    do {
                        try self.moveAccountToKinSDKIfNeeded(account)
                        return Promise(Void())
                    }
                    catch {
                        return Promise(error)
                    }
                default:
                    return Promise(KinMigrationError.migrateFailed(code: response.code, message: response.message))
                }
            }
    }

    private func migrateAccountIfNeeded(_ account: KinAccountProtocol) -> Promise<Void> {
        return needsToMigrateAccount(account).then { needsToMigrate -> Promise<Void> in
            if needsToMigrate {
                return self.migrateAccount(account)
            }
            else {
                do {
                    try self.moveAccountToKinSDKIfNeeded(account)
                    return Promise(Void())
                }
                catch {
                    return Promise(error)
                }
            }
        }
    }

    fileprivate func migrateAccounts() {
        guard version == .kinSDK else {
            delegate?.kinMigrationManager(self, error: KinMigrationError.unexpectedCondition)
            return
        }

        let promises = kinCoreClient.accounts.makeIterator().map({ migrateAccountIfNeeded($0) })

        DispatchQueue.global(qos: .background).async {
            await(promises)
                .then { _ in
                    DispatchQueue.main.async {
                        self.completed()
                    }
                }
                .error { error in
                    DispatchQueue.main.async {
                        self.delegate?.kinMigrationManager(self, error: error)
                    }
            }
        }
    }

    /**
     Move the Kin Core keychain account to the Kin SDK keychain.

     - Returns: True if there were no errors.
     */
    private func moveAccountToKinSDKIfNeeded(_ account: KinAccountProtocol) throws {
        let hasAccount = kinSDKClient.accounts.makeIterator().contains { kinSDKAccount -> Bool in
            return kinSDKAccount.publicAddress == account.publicAddress
        }

        guard hasAccount == false else {
            return
        }

        let json = try account.export(passphrase: "")
        let _ = try kinSDKClient.importAccount(json, passphrase: "")
    }
}
