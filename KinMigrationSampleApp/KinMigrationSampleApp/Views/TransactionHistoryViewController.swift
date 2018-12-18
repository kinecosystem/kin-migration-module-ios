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

    private var filteredTxs: [PaymentInfoProtocol]?

    private var watch: PaymentWatchProtocol?
    private var memoFilter = Observable<String?>()
    private let linkBag = LinkBag()
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .long
        return formatter
    }()

    init(account: KinAccountProtocol) {
        self.account = account

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let textField = UITextField()
        textField.delegate = self

        tableView.tableHeaderView = textField
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        watch = try? account.watchPayments(cursor: nil)
        watch?.emitter
            .accumulate(limit: 100)
            .combine(with: memoFilter)
            .map({ (payments, filterText) -> [PaymentInfoProtocol]? in
                return payments?.reversed().filter({ payment -> Bool in
                    guard let filterText = filterText else {
                        return true
                    }

                    if let filterText = filterText, !filterText.isEmpty {
                        return payment.memoText?.contains(filterText) ?? false
                    }

                    return true
                })
            })
            .on(next: { [weak self] payments in
                self?.filteredTxs = payments
            })
            .on(queue: .main, next: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .add(to: linkBag)
    }
}

// MARK: - Table View Data Source

extension TransactionHistoryViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTxs?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let tx = filteredTxs?[indexPath.row]
//
//        let cell: TxCell
//
//        let reuseIdentifier = tx.debit ? "OutgoingCell" : "IncomingCell"
//
//        cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TxCell

//        cell.addressLabel.text = tx.source == kinAccount.publicAddress ? tx.destination : tx.source
//        cell.amountLabel.text = String(describing: tx.amount)
//        cell.dateLabel.text = formatter.string(from: tx.createdAt)
//
//        cell.memoLabel.text = tx.memoText

        return UITableViewCell()
    }
}

// MARK: - Text Field Delegate

extension TransactionHistoryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        memoFilter.next((textField.text as NSString?)?.replacingCharacters(in: range, with: string))
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        memoFilter.next(nil)
        return true
    }
}
