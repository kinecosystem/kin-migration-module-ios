//
//  KinMigrationManager.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import Foundation

public protocol KinMigrationManagerDelegate: NSObjectProtocol {
    func kinMigrationManagerCanCreateClient(_ kinMigrationManager: KinMigrationManager, factory: KinClientFactory)
    func kinMigrationManagerError(_ kinMigrationManager: KinMigrationManager, error: Error)
}

public class KinMigrationManager {
    public weak var delegate: KinMigrationManagerDelegate? {
        didSet {
            // !!!: Debug
            version = .kin3
            // End Debug

            if needsToCreateClient {
                needsToCreateClient = false
                createClientIfPossible()
            }
        }
    }

    fileprivate(set) var version: Version? {
        didSet {
            createClientIfPossible()
        }
    }

    fileprivate(set) var state: State = .ready {
        didSet {
            syncState()
        }
    }

    let versionURL: URL

    public init(versionURL: URL) {
        self.versionURL = versionURL

        if isMigrated {
            needsToCreateClient = true
            version = .kin3
        }
        else {
            syncState()
        }
    }

    /**
     If the migration has already happened, this flag will have the client creation
     delegate called after all required properties have been set.
     */
    private var needsToCreateClient = false

    private func createClientIfPossible() {
        if let delegate = delegate, let version = version {
            delegate.kinMigrationManagerCanCreateClient(self, factory: KinClientFactory(version: version))
        }
    }
}

// MARK: - Version

extension KinMigrationManager {
    enum Version: String, Codable {
        case kin2
        case kin3
    }
}

// MARK: - State

extension KinMigrationManager {
    enum State {
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
            requestBurnAccount()
        case .migrateable:
            requestMigrateAccount()
        case .completed:
            isMigrated = true
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
        case responseFailed (Swift.Error)
        case decodingFailed (Swift.Error)
        case burnResponseFailed
        case migrateResponseFailed
        case internalInconsistency
    }
}

// MARK: - Requests

extension KinMigrationManager {
    private static let failedRetryChances = 3

    fileprivate func requestVersion() {
        perform(URLRequest(url: versionURL), responseType: Version.self)
            .then { [weak self] version in
                // ???: when setting the version here, it allows the KinClient to be created. does that cause problems?
                self?.version = version
                self?.state = .burnable
            }
            .error { [weak self] error in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.delegate?.kinMigrationManagerError(strongSelf, error: error)
        }
    }

    fileprivate func requestBurnAccount() {
        let urlRequest = URLRequest(url: URL(string: "")!)

        perform(urlRequest, responseType: Bool.self)
            .then { [weak self] isBurned in
                if isBurned {
                    self?.state = .migrateable
                }
                else if let strongSelf = self {
                    strongSelf.delegate?.kinMigrationManagerError(strongSelf, error: Error.burnResponseFailed)
                }
            }
            .error { [weak self] error in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.delegate?.kinMigrationManagerError(strongSelf, error: error)
        }
    }

    fileprivate func requestMigrateAccount() {
        let urlRequest = URLRequest(url: URL(string: "")!)

        perform(urlRequest, responseType: Bool.self)
            .then { [weak self] isMigrated in
                if isMigrated {
                    self?.state = .completed
                }
                else if let strongSelf = self {
                    strongSelf.delegate?.kinMigrationManagerError(strongSelf, error: Error.migrateResponseFailed)
                }
            }
            .error { [weak self] error in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.delegate?.kinMigrationManagerError(strongSelf, error: error)
        }
    }

    private func perform<T: Decodable>(_ urlRequest: URLRequest, responseType: T.Type, retryChances: Int = failedRetryChances) -> Promise<T> {
        let promise = Promise<T>()

        URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
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
                promise.signal(try JSONDecoder().decode(T.self, from: data))
            }
            catch {
                promise.signal(Error.decodingFailed(error))
            }
        }.resume()

        return promise
    }
}
