//
//  MainNavigationController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 13/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit
import KinMigrationModule

class MainNavigationController: UINavigationController {
    let migrationController = MigrationController()
    let networkViewController = NetworkViewController()

    private let loaderView = UIActivityIndicatorView(style: .whiteLarge)
    private var migrateAccountPromise: Promise<Void>?

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        networkViewController.testV2Button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        networkViewController.testV3Button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        networkViewController.mainButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)

        viewControllers = [networkViewController]

        migrationController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Flow

extension MainNavigationController {
    func pushAccountListViewController(client: KinClientProtocol) {
        var title = "\(client.network.description.capitalized) Accounts"

        if let version = migrationController.version?.rawValue {
            title = "Kin \(version) \(title)"
        }

        let viewController = AccountListViewController(with: client)
        viewController.delegate = self
        viewController.title = title
        pushViewController(viewController, animated: true)
    }

    private func pushAccountViewController(account: KinAccountProtocol) {
        guard let environment = migrationController.environment else {
            return
        }

        let viewController = AccountViewController(account, environment: environment)
        viewController.delegate = self
        pushViewController(viewController, animated: true)
    }
}

// MARK: - Network View Controller

extension MainNavigationController {
    @objc
    private func buttonAction(_ button: UIButton) {
        let environment: Environment

        if button == networkViewController.testV2Button {
            environment = .testKinCore
        }
        else if button == networkViewController.testV3Button {
            environment = .testKinSDK
        }
        else {
            environment = .mainKinCore
        }

        pushAccountListViewController(client: migrationController.client(for: environment))
    }
}

// MARK: - Account List View Controller

extension MainNavigationController: AccountListViewControllerDelegate {
    func accountListViewController(_ viewController: AccountListViewController, didSelect account: KinAccountProtocol) {
        pushAccountViewController(account: account)
    }
}

// MARK: - Account View Controller

extension MainNavigationController: AccountViewControllerDelegate {
    func accountViewController(_ viewController: AccountViewController, isMigrated account: KinAccountProtocol) -> Bool {
        return migrationController.isAccountMigrated(publicAddress: account.publicAddress)
    }

    func accountViewController(_ viewController: AccountViewController, migrate account: KinAccountProtocol) -> Promise<Void> {
        let promise = Promise<Void>()

        do {
            migrateAccountPromise = promise
            try migrationController.migrateAccount(with: account.publicAddress)
        }
        catch {
            dismissLoaderView()

            promise.signal(error)
            migrateAccountPromise = nil
        }

        return promise
    }
}

// MARK: - Migration Controller

extension MainNavigationController: MigrationControllerDelegate {
    func migrationController(_ controller: MigrationController, readyWith client: KinClientProtocol) {
        dismissLoaderView()

        migrateAccountPromise?.signal(Void())
        migrateAccountPromise = nil
    }

    func migrationController(_ controller: MigrationController, error: Error) {
        dismissLoaderView()

        migrateAccountPromise?.signal(error)
        migrateAccountPromise = nil
    }
}

// MARK: - Loader

extension MainNavigationController {
    fileprivate func presentLoaderView() {
        guard loaderView.superview == nil else {
            return
        }

        loaderView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        loaderView.translatesAutoresizingMaskIntoConstraints = false
        loaderView.startAnimating()
        view.addSubview(loaderView)
        loaderView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        loaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        loaderView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        loaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }

    fileprivate func dismissLoaderView() {
        guard loaderView.superview != nil else {
            return
        }

        loaderView.stopAnimating()
        loaderView.removeFromSuperview()
    }
}
