//
//  KinServiceProvider.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 06/01/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

public protocol ServiceProviderProtocol {
    var network: Network { get }
}

public struct ServiceProvider: ServiceProviderProtocol {
    private(set) public var network: Network

    /**
     Initializes and returns a service provider object having the given network.

     This class can not be used with a type `.custom` network.

     - Parameter network: The `Network` which the client connects to.

     - Throws: An error if the `network` is `.custom`.
     */
    public init(network: Network) throws {
        if case .custom = network {
            throw KinMigrationError.invalidNetwork
        }

        self.network = network
    }
}

public struct CustomServiceProvider: ServiceProviderProtocol {
    private(set) public var network: Network
    public let nodeURL: URL

    /**
     Initializes and returns a service provider object having the given network and node URL.

     This class can only be used with a type `.custom` network.

     - Parameter network: The `Network` which the client connects to.
     - Parameter nodeURL: The URL of the node.

     - Throws: An error if the `network` is not `.custom`.
     */
    public init(network: Network, nodeURL: URL) throws {
        guard case .custom = network else {
            throw KinMigrationError.invalidNetwork
        }

        self.network = network
        self.nodeURL = nodeURL
    }
}
