//
//  Constants.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 13/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinMigrationModule

extension AppId {
    init(network: Network) throws {
        switch network {
        case .testNet: try self.init("test")
        case .mainNet: try self.init("test") // TODO:
        default:       fatalError()
        }
    }
}

extension URL {
    static func node(_ network: Network) -> URL {
        switch network {
        case .mainNet: return URL(string: "https://horizon-ecosystem.kininfrastructure.com")!
        case .testNet: return URL(string: "http://horizon-testnet.kininfrastructure.com")!
        default:       fatalError()
        }
    }

    static func version(_ network: Network) -> URL {
        switch network { // TODO:
        case .mainNet: return URL(string: "http://kin.org")!
        case .testNet: return URL(string: "http://kin.org")!
        default:       fatalError()
        }
    }

    static func friendBot(_ network: Network) -> URL {
        switch network {
        case .testNet: return URL(string: "http://friendbot-testnet.kininfrastructure.com")!
        default:       fatalError("Friend bot is only supported on test net.")
        }
    }

    static func whitelist(_ network: Network) -> URL {
        switch network { // TODO:
        case .mainNet: return URL(string: "http://kin.org")!
        case .testNet: return URL(string: "http://kin.org")!
        default:       fatalError()
        }
    }
}
