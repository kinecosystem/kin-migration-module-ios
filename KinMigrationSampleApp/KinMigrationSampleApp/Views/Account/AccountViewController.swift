//
//  AccountViewController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 13/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit
import KinMigrationModule

class AccountViewController: UIViewController {
    let network: Network
    let migrationManager: KinMigrationManager

    init(network: Network) {
        self.network = network
        self.migrationManager = KinMigrationManager(versionURL: .version(network))

        super.init(nibName: nil, bundle: nil)

        migrationManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
    }
}

// MARK: - Migration Manager

extension AccountViewController: KinMigrationManagerDelegate {
    func kinMigrationManagerCanCreateClient(_ kinMigrationManager: KinMigrationManager, factory: KinClientFactory) {
        guard let appId = try? AppId(network: network) else {
            return
        }

        let client = factory.KinClient(with: .node(network), network: network, appId: appId)

        if let account = try? client.accounts.first ?? client.addAccount() {
            let whitelist = self.whitelist(url: .whitelist(network), network: network)

            account.sendTransaction(to: "", kin: 100, memo: nil, whitelist: whitelist)
                .then { transactionId -> Void in

            }
        }
    }

    func kinMigrationManagerError(_ kinMigrationManager: KinMigrationManager, error: Error) {
        
    }
}

// MARK: Whitelist

extension AccountViewController {
    private func whitelist(url: URL, network: Network) -> WhitelistClosure {
        return { transactionEnvelope -> Promise<TransactionEnvelope> in
            let promise: Promise<TransactionEnvelope> = Promise()
            let whitelistEnvelope = WhitelistEnvelope(transactionEnvelope: transactionEnvelope, networkId: network.id)

            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = try? JSONEncoder().encode(whitelistEnvelope)

            URLSession.shared.dataTask(with: request) { (data, response, error) in
                do {
                    promise.signal(try TransactionEnvelope.decodeResponse(data: data, error: error))
                }
                catch {
                    promise.signal(error)
                }
                }.resume()

            return promise
        }
    }
}
