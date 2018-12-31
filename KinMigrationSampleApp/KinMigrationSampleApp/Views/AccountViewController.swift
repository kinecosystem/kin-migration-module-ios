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

    private let createAccountPromise = Promise<Void>()
    private var watch: BalanceWatchProtocol?
    private let linkBag = LinkBag()

    private let datasource: [Row]
    private var balance: Kin?

    init(_ account: KinAccountProtocol, environment: Environment) {
        self.account = account
        self.environment = environment

        datasource = {
            var datasource: [Row] = [
                .publicAddress,
                .balance,
                .sendTransaction,
                .transactionHistory
            ]
            
            if environment.network != .mainNet {
                datasource.append(.createAccount)
            }
            if environment.blockchain == .stellar {
                datasource.append(.burnAccount)
            }

            return datasource
        }()

        super.init(nibName: nil, bundle: nil)

//        watchAccountActivation()
        watchAccountBalance()
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

    private func watchAccountActivation() {
        _ = try? account.watchCreation()
            .then { [weak self]  in
                self?.createAccountPromise.signal(Void())
            }
            .error { [weak self] error in
                self?.createAccountPromise.signal(error)
            }
    }

    @discardableResult
    private func activateAccount() -> Promise<Void> {
        let promise = Promise<Void>()

        _ = try? account.watchCreation()
            .then { [weak self] _ -> Promise<Void> in
                guard let strongSelf = self else {
                    return promise.signal(KinError.internalInconsistency)
                }

                return strongSelf.account.activate()
            }
            .then {
                promise.signal(Void())
            }
            .error { error in
                promise.signal(error)
        }

        return promise
    }

    @discardableResult
    private func fundAccount() -> Promise<Void> {
        let promise = Promise<Void>()
        let url: URL = .fund(environment, publicAddress: account.publicAddress, amount: 10000)

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

    private func burnAccount() -> Promise<String?> {
        return account.burn()
    }

    @discardableResult
    private func updateAccountBalance() -> Promise<Void> {
        let promise = Promise<Void>()

        account.balance()
            .then(on: .main, { [weak self] balance in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.balance = balance
                strongSelf.tableView.reloadData()

                promise.signal(Void())
            })
            .error { [weak self] error in
                DispatchQueue.main.async {
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

                    if case KinError.invalidAmount = error {
                        cell.detailTextLabel?.text = "N/A"
                    }
                    else {
                        cell.detailTextLabel?.text = error.localizedDescription
                    }

                    promise.signal(error)
                }
        }

        return promise
    }

    private func watchAccountBalance() {
        self.watch = try? account.watchBalance(nil)
        self.watch?.emitter
            .on(queue: .main, next: { [weak self] balance in
                self?.updateAccountBalance()
            })
            .add(to: linkBag)
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
        case burnAccount
    }
}

extension AccountViewController.Row {
    fileprivate var reuseIdentifier: String {
        switch self {
        case .publicAddress:
            return "subtitle"
        case .balance,
             .createAccount,
             .burnAccount:
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
        case .burnAccount:
            return "Burn Account"
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
            tableView.deselectRow(at: indexPath, animated: true)

        case .sendTransaction:
            let viewController = SendTransactionViewController(account: account, environment: environment)
            navigationController?.pushViewController(viewController, animated: true)

        case .transactionHistory:
            let viewController = TransactionHistoryViewController(account: account)
            navigationController?.pushViewController(viewController, animated: true)

        case .createAccount:
            let cell = tableView.cellForRow(at: indexPath)
            cell?.detailTextLabel?.text = "Creating..."

            createAccount()
                .then(on: .main, { [weak self] _ -> Promise<Void> in
                    guard let strongSelf = self else {
                        return Promise(Error.internalInconsistency)
                    }

                    cell?.detailTextLabel?.text = "Activating..."
                    return strongSelf.activateAccount()
                })
                .then(on: .main) { [weak self] _ -> Promise<Void> in
                    guard let strongSelf = self else {
                        return Promise(Error.internalInconsistency)
                    }

                    guard strongSelf.environment == .testKinCore else {
                        return Promise(Void())
                    }

                    cell?.detailTextLabel?.text = "Funding..."
                    return strongSelf.fundAccount()
                }
                .then(on: .main) { [weak self] _ -> Promise<Void> in
                    guard let strongSelf = self else {
                        return Promise(Error.internalInconsistency)
                    }

                    cell?.detailTextLabel?.text = "Updating..."
                    return strongSelf.updateAccountBalance()
                }
                .then(on: .main) { _ in
                    cell?.detailTextLabel?.text = nil
                    tableView.deselectRow(at: indexPath, animated: true)
            }

        case .burnAccount:
            let cell = tableView.cellForRow(at: indexPath)
            cell?.detailTextLabel?.text = "Burning..."

            burnAccount()
                .then(on: .main, { transactionHash in
                    if let _ = transactionHash {
                        cell?.detailTextLabel?.text = "Burned"
                    }
                    else {
                        cell?.detailTextLabel?.text = "Burned Already"
                    }
                })
                .error { error in
                    DispatchQueue.main.async {
                        cell?.detailTextLabel?.text = "Failed"
                    }
            }

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
