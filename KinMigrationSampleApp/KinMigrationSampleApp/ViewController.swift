//
//  ViewController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 11/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit
import KinMigrationModule

class ViewController: UIViewController {
    let migrationManager = KinMigrationManager(versionURL: URL.dev.version)

    override func viewDidLoad() {
        super.viewDidLoad()

        migrationManager.delegate = self
    }

    func whitelist(url: URL, network: Network) -> WhitelistClosure {
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

extension ViewController: KinMigrationManagerDelegate {
    func kinMigrationManagerCanCreateClient(_ kinMigrationManager: KinMigrationManager, factory: KinClientFactory) {
        guard let appId: AppId = .dev else {
            return
        }

        let client = factory.KinClient(with: URL.dev.node, network: .testNet, appId: appId)

        if let account = try? client.accounts.first ?? client.addAccount() {
            let whitelist = self.whitelist(url: URL.dev.whitelist, network: client.network)

            account.sendTransaction(to: "", kin: 100, memo: nil, whitelist: whitelist)
                .then { transactionId -> Void in

            }
        }
    }

    func kinMigrationManagerError(_ kinMigrationManager: KinMigrationManager, error: Error) {

    }
}
