//
//  KinClientFactory.swift
//  multi
//
//  Created by Corey Werner on 10/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import Foundation

class KinClientFactory {
    let version: KinVersion

    init(version: KinVersion) {
        self.version = version
    }

    private func nodeURL(_ network: Network, customNodeURL: URL? = nil) throws -> URL {
        switch network {
        case .custom:
            if let url = customNodeURL {
                return url
            }
            else {
                throw KinMigrationError.missingNodeURL
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

    func KinClient(network: Network, appId: AppId, nodeURL: URL? = nil) throws -> KinClientProtocol {
        let url = try self.nodeURL(network, customNodeURL: nodeURL)

        switch version {
        case .kinCore:
            return WrappedKinCoreClient(with: url, network: network, appId: appId)
        case .kinSDK:
            return WrappedKinSDKClient(with: url, network: network, appId: appId)
        }
    }
}
