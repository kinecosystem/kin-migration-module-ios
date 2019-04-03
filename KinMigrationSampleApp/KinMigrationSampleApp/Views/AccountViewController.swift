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

protocol AccountViewControllerDelegate: NSObjectProtocol {
    func accountViewController(_ viewController: AccountViewController, isMigrated account: KinAccountProtocol) -> Bool
    func accountViewController(_ viewController: AccountViewController, migrate account: KinAccountProtocol) -> Promise<Void>
}

class AccountViewController: UITableViewController {
    let account: KinAccountProtocol
    let environment: Environment

    weak var delegate: AccountViewControllerDelegate?

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

            if environment.blockchain == .stellar && environment.network == .testNet {
                datasource.append(.migrateAccount)
            }

            return datasource
        }()

        super.init(nibName: nil, bundle: nil)

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

            guard let data = data, let _ = try? JSONSerialization.jsonObject(with: data, options: []) else {
                promise.signal(Error.invalidResponse(message: nil))
                return
            }

            promise.signal(Void())
        }).resume()

        return promise
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
        let url: URL = .fund(environment, publicAddress: account.publicAddress, amount: 1000)

        URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            if let error = error {
                promise.signal(error)
                return
            }

            guard let data = data, let d = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                promise.signal(Error.invalidResponse(message: nil))
                return
            }

            guard let success = d?["success"] as? Bool, success == true else {
                promise.signal(Error.invalidResponse(message: d?["error"] as? String))
                return
            }

            promise.signal(Void())
        }).resume()

        return promise
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

                if let indexPath = strongSelf.tableViewIndexPath(for: .balance) {
                    strongSelf.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                else {
                    strongSelf.tableView.reloadData()
                }

                promise.signal(Void())
            })
            .error { [weak self] error in
                DispatchQueue.main.async {
                    guard let strongSelf = self else {
                        return
                    }

                    guard let cell = strongSelf.tableViewCell(for: .balance) else {
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

    @discardableResult
    private func migrateAccount() -> Promise<Void> {
        guard let delegate = delegate else {
            return Promise(KinMigrationError.missingDelegate)
        }

        return delegate.accountViewController(self, migrate: account)
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
        case migrateAccount
    }
}

extension AccountViewController.Row {
    fileprivate var reuseIdentifier: String {
        switch self {
        case .publicAddress:
            return "subtitle"
        case .balance,
             .createAccount,
             .migrateAccount:
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
        case .migrateAccount:
            return "Migrate Account"
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
        else if row == .migrateAccount {
            let isMigrated = delegate?.accountViewController(self, isMigrated: account) ?? false
            cell.detailTextLabel?.text = isMigrated ? "Migrated" : nil
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
            print(account.publicAddress)

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
                .then(on: .main) { _ in
                    cell?.detailTextLabel?.text = nil
                }
                .error { error in
                    print(error)

                    DispatchQueue.main.async {
                        cell?.detailTextLabel?.text = "Error"
                    }
                }
                .finally {
                    DispatchQueue.main.async {
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
            }

        case .migrateAccount:
            let cell = tableView.cellForRow(at: indexPath)
            cell?.detailTextLabel?.text = "Migrating..."

            migrateAccount()
                .then(on: .main) {
                    cell?.detailTextLabel?.text = "Migrated"
                }
                .error { error in
                    print(error)

                    DispatchQueue.main.async {
                        cell?.detailTextLabel?.text = "Error"
                    }
                }
                .finally {
                    DispatchQueue.main.async {
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
            }

        default:
            break
        }
    }
}

// MARK: Table View

extension AccountViewController {
    fileprivate func tableViewIndexPath(for row: Row) -> IndexPath? {
        guard let balanceIndex = datasource.firstIndex(of: row) else {
            return nil
        }

        return IndexPath(row: balanceIndex, section: 0)
    }

    fileprivate func tableViewCell(for row: Row) -> UITableViewCell? {
        guard let indexPath = tableViewIndexPath(for: row) else {
            return nil
        }

        return tableView.cellForRow(at: indexPath)
    }
}

// MARK: - Error

extension AccountViewController {
    enum Error: Swift.Error {
        case invalidResponse (message: String?)
        case internalInconsistency
    }
}
