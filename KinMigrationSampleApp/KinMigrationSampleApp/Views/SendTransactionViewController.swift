//
//  SendTransactionViewController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 20/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit
import KinMigrationModule

class SendTransactionViewController: UIViewController {
    private let addressTextField = UITextField()
    private let amountTextField = UITextField()
    private let memoTextField = UITextField()
    private let whitelistControl = UISegmentedControl(items: ["Whitelist Enabled", "Whitelist Disabled"])
    private let sendButton = SendTransactionButton()

    let account: KinAccountProtocol
    let environment: Environment

    init(account: KinAccountProtocol, environment: Environment) {
        self.account = account
        self.environment = environment

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: stackView.spacing).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true

        func whitespaceView() -> UIView {
            return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: stackView.spacing))
        }

        let addressLabel = UILabel()
        addressLabel.text = "Address"
        stackView.addArrangedSubview(addressLabel)

        addressTextField.delegate = self
        addressTextField.borderStyle = .roundedRect
        stackView.addArrangedSubview(addressTextField)

        stackView.addArrangedSubview(whitespaceView())

        let amountLabel = UILabel()
        amountLabel.text = "Amount"
        stackView.addArrangedSubview(amountLabel)

        amountTextField.delegate = self
        amountTextField.borderStyle = .roundedRect
        amountTextField.keyboardType = .numberPad
        stackView.addArrangedSubview(amountTextField)

        stackView.addArrangedSubview(whitespaceView())

        let memoLabel = UILabel()
        memoLabel.text = "Memo"
        stackView.addArrangedSubview(memoLabel)

        memoTextField.delegate = self
        memoTextField.borderStyle = .roundedRect
        stackView.addArrangedSubview(memoTextField)

        stackView.addArrangedSubview(whitespaceView())

        if environment.blockchain == .kin {
            whitelistControl.selectedSegmentIndex = 0
            stackView.addArrangedSubview(whitelistControl)

            stackView.addArrangedSubview(whitespaceView())
        }

        sendButton.backgroundColor = whitelistControl.tintColor
        sendButton.addTarget(self, action: #selector(sendAction(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(sendButton)
    }
}

// MARK: - Send Button

extension SendTransactionViewController {
    @objc
    private func sendAction(_ button: SendTransactionButton) {
        guard let address = addressTextField.text, !address.isEmpty else {
            addressTextField.backgroundColor = .red
            return
        }

        guard let amount = amountTextField.text, let kin = Kin(string: amount) else {
            amountTextField.backgroundColor = .red
            return
        }

        let whitelist: WhitelistClosure

        if whitelistControl.selectedSegmentIndex == 0 && environment.blockchain == .kin {
            whitelist = MigrationController.whitelist(url: .whitelist(environment), networkId: environment.networkId)
        }
        else {
            whitelist = { Promise($0) }
        }

        button.sendState = .sending

        // TODO: test client.minFee()

        account.sendTransaction(to: address, kin: kin, memo: memoTextField.text, fee: 0, whitelist: whitelist)
            .then(on: .main, { transactionId in
                button.sendState = .sent
            })
            .error { error in
                DispatchQueue.main.async {
                    button.sendState = .failed
                }
        }
    }
}

// MARK: - Text Field Delegate

extension SendTransactionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.backgroundColor = nil

        if sendButton.sendState != .sending {
            sendButton.sendState = .ready
        }
    }
}
