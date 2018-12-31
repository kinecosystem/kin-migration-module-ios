//
//  KinClientFactory.swift
//  multi
//
//  Created by Corey Werner on 10/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import Foundation

class KinClientFactory {
    let version: KinMigrationManager.Version

    init(version: KinMigrationManager.Version) {
        self.version = version
    }

    private func nodeURL(_ network: Network, customURL: URL? = nil) throws -> URL {
        switch network {
        case .custom:
            if let url = customURL {
                return url
            }
            else {
                throw KinMigrationManager.Error.missingCustomURL
            }
        case .mainNet:
            switch version {
            case .kinCore:
                return URL(string: "https://horizon-ecosystem.kininfrastructure.com")!
            case .kinSDK:
                return URL(string: "http://kin.org")!
            }
        default:
            switch version {
            case .kinCore:
                return URL(string: "http://horizon-playground.kininfrastructure.com")!
            case .kinSDK:
                return URL(string: "http://horizon-testnet.kininfrastructure.com")!
            }
        }
    }

    func KinClient(network: Network, appId: AppId, customURL: URL? = nil) throws -> KinClientProtocol {
        let url = try nodeURL(network, customURL: customURL)

        switch version {
        case .kinCore:
            return WrappedKinCoreClient(with: url, network: network)
        case .kinSDK:
            return WrappedKinSDKClient(with: url, network: network, appId: appId)
        }
    }
}
