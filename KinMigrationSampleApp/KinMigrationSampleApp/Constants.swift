//
//  Constants.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 13/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinMigrationModule

extension AppId {
    static let dev = try? AppId("test")
}

extension URL {
    static let dev = Dev()

    class Dev {
        let node = URL(string: "http://horizon-testnet.kininfrastructure.com")!
        let version = URL(string: "http://kin.org")! // TODO:
        let friendBot = URL(string: "http://friendbot-testnet.kininfrastructure.com")!
        let whitelist = URL(string: "http://kin.org")! // TODO:
    }
}
