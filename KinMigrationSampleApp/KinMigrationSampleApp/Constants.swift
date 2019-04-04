//
//  Constants.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 13/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinMigrationModule

enum Environment {
    case testKinCore
    case testKinSDK
    case mainKinCore
    case mainKinSDK
}

extension Environment {
    var network: Network {
        switch self {
        case .testKinCore, .testKinSDK:
            return .testNet
        case .mainKinCore, .mainKinSDK:
            return .mainNet
        }
    }

    var networkId: String {
        switch self {
        case .testKinCore, .mainKinCore:
            return network.kinCoreId
        case .testKinSDK, .mainKinSDK:
            return network.kinSDKId
        }
    }

    enum Blockchain {
        case stellar
        case kin
    }

    var blockchain: Blockchain {
        switch self {
        case .testKinCore, .mainKinCore:
            return .stellar
        case .testKinSDK, .mainKinSDK:
            return .kin
        }
    }
}

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
    /**
     The Kin version to be used.

     The JSON response should look like `{"version": 2}` for Kin Core and `{"version": 3}`
     for Kin SDK.

     - SeeAlso: https://www.mocky.io/
     */
    static func version(_ environment: Environment) -> URL {
        switch environment {
        case .testKinCore: return URL(string: "http://www.mocky.io/v2/5c2db8cd2f0000a3301751e3")!
        case .mainKinCore: fatalError("Not yet implemented.")
        default:           fatalError("Migration version is only needed for the Kin Core.")
        }
    }

    static func migrate(_ environment: Environment) -> URL {
        switch environment {
        case .testKinCore: return URL(string: "https://migration-devplatform-playground.developers.kinecosystem.com")!
        case .mainKinCore: fatalError("Not yet implemented.")
        default:           fatalError("Migration is only needed for Kin Core.")
        }
    }

    static func friendBot(_ environment: Environment, publicAddress: String) -> URL {
        switch environment {
        case .testKinCore: return URL(string: "http://friendbot-playground.kininfrastructure.com?addr=\(publicAddress)")!
        case .testKinSDK:  return URL(string: "http://friendbot-testnet.kininfrastructure.com?addr=\(publicAddress)")!
        default:           fatalError("Friend bot is only supported on test net.")
        }
    }

    static func fund(_ environment: Environment, publicAddress: String, amount: Kin) -> URL {
        switch environment {
        case .testKinCore: return URL(string: "http://faucet-playground.kininfrastructure.com/fund?account=\(publicAddress)&amount=\(amount)")!
        case .testKinSDK:  return URL(string: "http://friendbot-testnet.kininfrastructure.com/fund?addr=\(publicAddress)&amount=\(amount)")!
        default:           fatalError("Funding is only supported on test net.")
        }
    }

    static func whitelist(_ environment: Environment) -> URL {
        switch environment {
        case .testKinSDK: return URL(string: "http://34.239.111.38:3000/whitelist")!
        case .mainKinSDK: fatalError("Not yet implemented.")
        default:          fatalError("Whitelisting is only for Kin SDK.")
        }
    }
}
