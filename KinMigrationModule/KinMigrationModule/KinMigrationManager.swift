//
//  KinMigrationManager.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import Foundation
import KinUtil

public protocol KinMigrationManagerDelegate: NSObjectProtocol {
    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, didCreateClient client: KinClientProtocol)
    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, error: Error)
}

public class KinMigrationManager {
    public weak var delegate: KinMigrationManagerDelegate?

    public let network: Network
    public let appId: AppId

    /**
     Custom node URL

     When using a custom network, the node url needs to be provided.
     */
    public var nodeURL: URL?

    public init(network: Network, appId: AppId) {
        self.network = network
        self.appId = appId
    }

    fileprivate var state: State = .ready {
        didSet {
            syncState()
        }
    }

    fileprivate var version: Version?

    fileprivate var versionURL: URL?

    public func start(withVersionURL versionURL: URL) throws {
        guard self.versionURL != versionURL else {
            return
        }

        self.versionURL = versionURL

        guard delegate != nil else {
            throw Error.missingDelegate
        }

        // !!!: DEBUG
//        if isMigrated {
//            version = .kinSDK
//            delegateClientCreation()
//        }
//        else {
            syncState()
//        }
    }

    fileprivate lazy var kinCoreClient: KinClientProtocol? = {
        return self.createClient(version: .kinCore)
    }()

    fileprivate lazy var kinSDKClient: KinClientProtocol? = {
        return self.createClient(version: .kinSDK)
    }()

    fileprivate var burnedKinCoreAccounts: [KinAccountProtocol] = []
}

// MARK: - Version

extension KinMigrationManager {
    enum Version: String, Codable {
        case kinCore
        case kinSDK
    }
}

extension KinMigrationManager.Version {
    init?(version: String) {
        switch version {
        case "2":
            self = .kinCore
        case "3":
            self = .kinSDK
        default:
            return nil
        }
    }
}

// MARK: - State

extension KinMigrationManager {
    fileprivate enum State {
        case ready
        case burnable
        case migrateable
        case completed
    }

    fileprivate func syncState() {
        switch state {
        case .ready:
            requestVersion()
        case .burnable:
            burnAccounts()
        case .migrateable:
            requestMigrateAccount()
        case .completed:
            isMigrated = true
            delegateClientCreation()
        }
    }

    public private(set) var isMigrated: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "KinMigrationDidMigrateToKin3")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "KinMigrationDidMigrateToKin3")
        }
    }
}

// MARK: - Error

extension KinMigrationManager {
    public enum Error: Swift.Error {
        case missingDelegate
        case missingCustomURL
        case responseFailed (Swift.Error)
        case decodingFailed (Swift.Error)
        case burnAccountFailed (KinAccountProtocol, Swift.Error)
        case burnFailed
        case migrateAccountFailed (KinAccountProtocol, Swift.Error)
        case migrateResponseFailed (code: Int, message: String)
        case internalInconsistency
    }
}

// MARK: - Requests

extension KinMigrationManager {
    private static let failedRetryChances = 3

    fileprivate func requestVersion() {
        guard let versionURL = versionURL else {
            return
        }

        perform(URLRequest(url: versionURL))
            .then(on: .main, { [weak self] response in
                guard let version = Version(version: response.message) else {
                    // TODO: error
                    return
                }

                self?.version = version

                if version == .kinSDK {
                    self?.state = .burnable
                }
                else {
                    self?.delegateClientCreation()
                }
            })
            .error { [weak self] error in
                DispatchQueue.main.async {
                    guard let strongSelf = self else {
                        return
                    }

                    strongSelf.delegate?.kinMigrationManager(strongSelf, error: error)
                }
        }
    }

    fileprivate func requestMigrateAccount(_ account: KinAccountProtocol) -> Promise<Void> {
        let promise = Promise<Void>()

        var urlRequest = URLRequest(url: URL(string: "http://10.4.59.1:8000/migrate?address=\(account.publicAddress)")!)
        urlRequest.httpMethod = "POST"

        perform(urlRequest)
            .then { response in
                if response.code == 200 {
                    promise.signal(Void())
                }
                else {
                    promise.signal(Error.migrateResponseFailed(code: response.code, message: response.message))
                }
            }
            .error { error in
                promise.signal(error)
        }

        return promise
    }

    fileprivate func requestMigrateAccounts() {
        guard version == .kinSDK else {
            return
        }

        let promises = burnedKinCoreAccounts.map { account -> Promise<Void> in
            return requestMigrateAccount(account)
                .error { [weak self] error in
                    DispatchQueue.main.async {
                        guard let strongSelf = self else {
                            return
                        }

                        strongSelf.delegate?.kinMigrationManager(strongSelf, error: Error.migrateAccountFailed(account, error))
                    }
            }
        }

        do {
            // TODO:
            let a = try await(promises)
        }
        catch {

        }
    }

    private func perform(_ urlRequest: URLRequest, retryChances: Int = failedRetryChances) -> Promise<KinResponse> {
        let promise = Promise<KinResponse>()

        URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, _, error) in
            if let error = error {
                if retryChances > 0, let strongSelf = self {
                    strongSelf.perform(urlRequest, retryChances: retryChances - 1)
                        .then { promise.signal($0) }
                        .error { promise.signal($0) }
                }
                else {
                    promise.signal(Error.responseFailed(error))
                }
                return
            }

            guard let data = data else {
                promise.signal(Error.internalInconsistency)
                return
            }

            do {
                promise.signal(try JSONDecoder().decode(KinResponse.self, from: data))
            }
            catch {
                promise.signal(Error.decodingFailed(error))
            }
        }.resume()

        return promise
    }
}

// MARK: - Client / Account

extension KinMigrationManager {
    fileprivate func createClient(version: Version) -> KinClientProtocol? {
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

        guard let client = createClient(version: version) else {
            return
        }

        delegate?.kinMigrationManager(self, didCreateClient: client)
    }

    /**
     Burn the Kin Core accounts

     This function supports burning multiple accounts.

     If the client has multiple accounts and at least one account succeeded,
     an error will be delegated for each failed account, but the migration
     will continue.

     If the client has one or multiple accounts which all fail, an error will
     be delegated for each failed account along with an error that burning
     failed.
     */
    fileprivate func burnAccounts() {
        guard version == .kinSDK else {
            return
        }

        guard let client = kinCoreClient else {
            return
        }

        var burnedKinCoreAccounts: [KinAccountProtocol] = []

        let promises = client.accounts.makeIterator().map { account -> Promise<String?> in
            return account.burn()
                .then { transactionHash in
                    burnedKinCoreAccounts.append(account)
                }
                .error { [weak self] error in
                    DispatchQueue.main.async {
                        guard let strongSelf = self else {
                            return
                        }

                        strongSelf.delegate?.kinMigrationManager(strongSelf, error: Error.burnAccountFailed(account, error))
                    }
            }
        }

        do {
            // TODO: await should properly handle `.then`
            Promise(try await(promises))
                .then { [weak self] _ in
                    DispatchQueue.main.async {
                        guard let strongSelf = self else {
                            return
                        }

                        if burnedKinCoreAccounts.isEmpty {
                            strongSelf.delegate?.kinMigrationManager(strongSelf, error: Error.burnFailed)
                        }
                        else {
                            // ???: by removing the state, which isnt needed, you can pass the accounts to a func
                            strongSelf.burnedKinCoreAccounts = burnedKinCoreAccounts
                            strongSelf.state = .migrateable
                        }
                    }
                }
                .error { [weak self] error in
                    DispatchQueue.main.async {
                        guard let strongSelf = self else {
                            return
                        }

                        strongSelf.delegate?.kinMigrationManager(strongSelf, error: error)
                    }
            }
        }
        catch {
            delegate?.kinMigrationManager(self, error: error)
        }
    }
}
