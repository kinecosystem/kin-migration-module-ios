//
//  KinClientFactory.swift
//  multi
//
//  Created by Corey Werner on 10/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import Foundation

public class KinClientFactory {
    let version: KinMigrationManager.Version

    init(version: KinMigrationManager.Version) {
        self.version = version
    }

    private func blockchainURL(_ network: Network) -> URL {
        switch network {
        case .custom(let urlString):
            return URL(string: urlString)!
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

    public func KinClient(network: Network, appId: AppId) -> KinClientProtocol {
        let url = blockchainURL(network)

        switch version {
        case .kinCore:
            return WrappedKinCoreClient(with: url, network: network)
        case .kinSDK:
            return WrappedKinSDKClient(with: url, network: network, appId: appId)
        }
    }
}
