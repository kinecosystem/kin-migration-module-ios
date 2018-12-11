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

    public func KinClient(with url: URL, network: Network, appId: AppId) -> KinClientProtocol {
        switch version {
        case .kin2:
            return WrappedKinCoreClient(with: url, network: network)
        case .kin3:
            return WrappedKinSDKClient(with: url, network: network, appId: appId)
        }
    }
}
