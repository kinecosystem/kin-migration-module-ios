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
    let migrationManager = KinMigrationManager(versionURL: URL(string: "http://kin.org")!)

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

            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                do {
                    promise.signal(try TransactionEnvelope.decodeResponse(data: data, error: error))
                }
                catch {
                    promise.signal(error)
                }
            }

            task.resume()

            return promise
        }
    }
}

extension ViewController: KinMigrationManagerDelegate {
    func kinMigrationManagerCanCreateClient(_ kinMigrationManager: KinMigrationManager, factory: KinClientFactory) {
        guard let appId = try? AppId("aaaa") else {
            return
        }

        let client = factory.KinClient(with: URL(string: "http://kin.org")!, network: .testNet, appId: appId)

        if let account = try? client.accounts.first ?? client.addAccount() {
            let url = URL(string: "http://kin.org")!
            let whitelist = self.whitelist(url: url, network: client.network)

            account.sendTransaction(to: "", kin: 100, memo: nil, whitelist: whitelist)
                .then { transactionId -> Void in

            }
        }
    }

    func kinMigrationManagerError(_ kinMigrationManager: KinMigrationManager, error: Error) {

    }
}
