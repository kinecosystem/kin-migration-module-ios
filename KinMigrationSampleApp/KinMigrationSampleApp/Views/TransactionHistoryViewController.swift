//
//  TransactionHistoryViewController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 17/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit
import KinMigrationModule

class TransactionHistoryViewController: UITableViewController {
    private let account: KinAccountProtocol
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .long
        return formatter
    }()

    init(account: KinAccountProtocol) {
        self.account = account

        super.init(nibName: nil, bundle: nil)

        watchTransactions()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Filter Transactions"
        searchBar.sizeToFit()

        tableView.tableHeaderView = searchBar
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: Transactions

    private var watch: PaymentWatchProtocol?
    private var transactions: [PaymentInfoProtocol] = []
    private var memoFilter = Observable<String?>()
    private let linkBag = LinkBag()

    private func watchTransactions() {
        watch = try? account.watchPayments(cursor: nil)
        watch?.emitter
            .accumulate(limit: 100)
            .combine(with: memoFilter)
            .map({ (payments, filterText) -> [PaymentInfoProtocol]? in
                return payments?.reversed().filter({ payment -> Bool in
                    guard let filterText = filterText as? String else {
                        return true
                    }

                    if !filterText.isEmpty {
                        return payment.memoText?.contains(filterText) ?? false
                    }

                    return true
                })
            })
            .on(next: { [weak self] payments in
                if let payments = payments {
                    self?.transactions = payments
                }
            })
            .on(queue: .main, next: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .add(to: linkBag)
    }
}

// MARK: - Table View Data Source

extension TransactionHistoryViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        if let cell = cell as? TransactionTableViewCell {
            let tx = transactions[indexPath.row]

            cell.contentView.backgroundColor = tx.debit ? .outgoingCell : .incomingCell
            cell.addressLabel.text = tx.source == account.publicAddress ? tx.destination : tx.source
            cell.amountLabel.text = "\(tx.amount) KIN"
            cell.dateLabel.text = formatter.string(from: tx.createdAt)
            cell.memoLabel.text = tx.memoText
        }

        return cell
    }
}

// MARK: - Search Bar Delegate

extension TransactionHistoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        memoFilter.next(searchText.trimmingCharacters(in: .whitespaces))
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        memoFilter.next(nil)
    }
}

// MARK: -

extension UIColor {
    fileprivate static let outgoingCell = UIColor(red: 255/255, green: 240/255, blue: 240/255, alpha: 1)
    fileprivate static let incomingCell = UIColor(red: 240/255, green: 255/255, blue: 240/255, alpha: 1)
}
