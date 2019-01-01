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
    static func version(_ environment: Environment) -> URL {
        switch environment { // https://www.mocky.io/
        case .testKinCore: return URL(string: "http://www.mocky.io/v2/5c2b5e403000007400abaf90")!
        case .testKinSDK:  return URL(string: "http://www.mocky.io/v2/5c2b5e5b3000007400abaf91")!
        case .mainKinCore: return URL(string: "http://kin.org")!
        case .mainKinSDK:  return URL(string: "http://kin.org")!
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
        case .testKinSDK:  return URL(string: "http://kin.org?addr=\(publicAddress)&amount=\(amount)")! // TODO:
        default:           fatalError("Funding is only supported on test net.")
        }
    }

    static func whitelist(_ environment: Environment) -> URL {
        switch environment { // TODO:
        case .testKinSDK:  return URL(string: "http://10.4.59.1:3003/whitelist")!
        case .mainKinSDK:  return URL(string: "http://kin.org")!
        default:           fatalError("Whitelisting is only for Kin 3")
        }
    }
}
