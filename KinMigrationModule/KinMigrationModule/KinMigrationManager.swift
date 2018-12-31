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
    func kinMigrationManagerPreparingClient(_ kinMigrationManager: KinMigrationManager) -> KinClientPreparation
    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, didCreateClient client: KinClientProtocol)
    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, error: Error)
}

public class KinMigrationManager {
    public weak var delegate: KinMigrationManagerDelegate?

    public init() {

    }

    fileprivate var state: State = .ready {
        didSet {
            syncState()
        }
    }

    fileprivate(set) var version: Version?

    fileprivate var versionURL: URL?

    public func start(withVersionURL versionURL: URL) throws {
        guard self.versionURL != versionURL else {
            return
        }

        self.versionURL = versionURL

        guard delegate != nil else {
            throw Error.missingDelegate
        }

//        if isMigrated {
//            version = .kinSDK
//            delegateClientCreation()
//        }
//        else {
            syncState()
//        }
    }

    fileprivate var publicAddresses: [String]?
}

// MARK: - Version

extension KinMigrationManager {
    public enum Version: String, Codable {
        case kinCore
        case kinSDK
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
        case migrateResponseFailed
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

        perform(URLRequest(url: versionURL), responseType: Version.self)
            .then(on: .main, { [weak self] version in
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

    fileprivate func requestMigrateAccount() {
        guard version == .kinSDK else {
            return
        }

        let urlRequest = URLRequest(url: URL(string: "http://kin.org")!)

        perform(urlRequest, responseType: Bool.self)
            .then(on: .main, { [weak self] isMigrated in
                if isMigrated {
                    self?.state = .completed
                }
                else if let strongSelf = self {
                    strongSelf.delegate?.kinMigrationManager(strongSelf, error: Error.migrateResponseFailed)
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

    private func perform<T: Codable>(_ urlRequest: URLRequest, responseType: T.Type, retryChances: Int = failedRetryChances) -> Promise<T> {
        let promise = Promise<T>()

        URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, _, error) in
            if let error = error {
                if retryChances > 0, let strongSelf = self {
                    strongSelf.perform(urlRequest, responseType: T.self, retryChances: retryChances - 1)
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
                let response = try JSONDecoder().decode(KinResponse<T>.self, from: data)
                promise.signal(response.success)
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
        guard let prep = delegate?.kinMigrationManagerPreparingClient(self) else {
            delegate?.kinMigrationManager(self, error: Error.missingDelegate)
            return nil
        }

        do {
            let factory = KinClientFactory(version: version)
            return try factory.KinClient(network: prep.network, appId: prep.appId, customURL: prep.nodeURL)
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

    fileprivate func burnAccounts() {
        guard version == .kinSDK else {
            return
        }

        guard let accounts = createClient(version: .kinCore)?.accounts else {
            return
        }

        let promises = accounts.makeIterator().map { account -> Promise<String?> in
            return account.burn()
                .then({ _ in
                    print("||| made it")
                })
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
            let p = Promise(try await(promises))
            p
                .then(on: .main, { [weak self] _ in
                    self?.state = .migrateable
                })
                .error { error in
                    self.state = .migrateable
            }
        }
        catch {
            self.state = .completed
            print("")
        }



//        let promise = Promise<[String?]>()
//
//        do {
//            promise.signal(try await(promises))
//        }
//        catch {
//
//        }
                

    }
}
