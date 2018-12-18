//
//  AccountViewController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 13/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit
import KinMigrationModule
import StellarErrors

class AccountViewController: UITableViewController {
    let account: KinAccountProtocol
    let environment: Environment

    private let datasource: [Row]
    private var balance: Kin?

    init(_ account: KinAccountProtocol, environment: Environment) {
        self.account = account
        self.environment = environment

        if environment.network == .mainNet {
            datasource = [
                .publicAddress,
                .balance,
                .sendTransaction,
                .transactionHistory
            ]
        }
        else {
            datasource = [
                .publicAddress,
                .balance,
                .sendTransaction,
                .transactionHistory,
                .createAccount
            ]
        }

        super.init(nibName: nil, bundle: nil)

        updateAccountBalance()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        tableView.tableFooterView = UIView()
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "subtitle")
        tableView.register(Value1TableViewCell.self, forCellReuseIdentifier: "value1")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
    }
}

// MARK: - Account

extension AccountViewController {
    @discardableResult
    private func createAccount() -> Promise<Void> {
        let promise = Promise<Void>()
        let url: URL = .friendBot(environment, publicAddress: account.publicAddress)
        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                promise.signal(error)
                return
            }

            guard let data = data, let _ = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                promise.signal(Error.invalidResponse)
                return
            }

            promise.signal(Void())
        }).resume()

        return promise
    }

    @discardableResult
    private func fundAccount() -> Promise<Void> {
        let promise = Promise<Void>()
        let url: URL = .fund(environment, publicAddress: account.publicAddress, amount: 5000)

        URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            if let error = error {
                promise.signal(error)
                return
            }

            guard let data = data, let _ = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                promise.signal(Error.invalidResponse)
                return
            }

            promise.signal(Void())
        }).resume()

        return promise
    }

    private func updateAccountBalance() {
        account.balance()
            .then(on: .main, { [weak self] balance in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.balance = balance
                strongSelf.tableView.reloadData()
            })
            .error { [weak self] error in
                guard let strongSelf = self else {
                    return
                }

                guard let balanceIndex = strongSelf.datasource.firstIndex(of: .balance) else {
                    return
                }

                let indexPath = IndexPath(row: balanceIndex, section: 0)

                guard let cell = strongSelf.tableView.cellForRow(at: indexPath) else {
                    return
                }

                if case KinError.missingAccount = error {
                    cell.detailTextLabel?.text = "Missing Account"
                }
                else {
                    cell.detailTextLabel?.text = "?"
                }

        }
    }
}

// MARK: - Data Source

extension AccountViewController {
    fileprivate enum Row {
        case publicAddress
        case balance
        case sendTransaction
        case transactionHistory
        case createAccount
    }
}

extension AccountViewController.Row {
    fileprivate var reuseIdentifier: String {
        switch self {
        case .publicAddress:
            return "subtitle"
        case .balance,
             .createAccount:
            return "value1"
        case .sendTransaction,
             .transactionHistory:
            return "default"
        }
    }

    fileprivate var title: String {
        switch self {
        case .publicAddress:
            return "Public Address"
        case .balance:
            return "Balance"
        case .sendTransaction:
            return "Send Transaction"
        case .transactionHistory:
            return "Transaction History"
        case .createAccount:
            return "Create Account"
        }
    }
}

// MARK: - Table View Data Source

extension AccountViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = datasource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        cell.textLabel?.text = row.title

        if row == .publicAddress {
            cell.detailTextLabel?.text = account.publicAddress
        }
        else if row == .balance {
            if let balance = balance {
                cell.detailTextLabel?.text = "\(balance) KIN"
            }
            else {
                cell.detailTextLabel?.text = "Loading..."
            }
        }

        return cell
    }
}

// MARK: - Table View Delegate

extension AccountViewController {
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let row = datasource[indexPath.row]

        switch row {
        case .balance:
            return false
        default:
            return true
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = datasource[indexPath.row]

        switch row {
        case .publicAddress:
            UIPasteboard.general.string = account.publicAddress

        case .sendTransaction:
            break

        case .transactionHistory:
            let viewController = TransactionHistoryViewController(account: account)
            navigationController?.pushViewController(viewController, animated: true)

        case .createAccount:
            let cell = tableView.cellForRow(at: indexPath)
            cell?.detailTextLabel?.text = "Creating..."

            createAccount().then(on: .main, { [weak self] in
                cell?.detailTextLabel?.text = nil
                self?.updateAccountBalance()
            })
            
        default:
            break
        }
    }
}

// MARK: - Error

extension AccountViewController {
    enum Error: Swift.Error {
        case invalidResponse
        case internalInconsistency
    }
}
