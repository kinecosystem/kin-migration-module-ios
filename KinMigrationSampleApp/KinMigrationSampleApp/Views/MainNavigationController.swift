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

// MARK: - Network View Controller

extension MainNavigationController {
    @objc
    private func buttonAction(_ button: UIButton) {
        presentLoaderView()

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

        migrationController.startManager(with: environment)
    }
}

// MARK: - Migration Controller

extension MainNavigationController: MigrationControllerDelegate {
    func migrationController(_ controller: MigrationController, readyWith client: KinClientProtocol) {
        dismissLoaderView()

        let viewController = AccountListViewController(with: client)
        viewController.delegate = self

        if let network = controller.environment?.network {
            viewController.title = "\(network.description.capitalized) Accounts"
        }

        pushViewController(viewController, animated: true)
    }

    func migrationController(_ controller: MigrationController, error: Error) {
        dismissLoaderView()
    }
}

// MARK: - Account List View Controller

extension MainNavigationController: AccountListViewControllerDelegate {
    func accountListViewController(_ viewController: AccountListViewController, didSelect account: KinAccountProtocol) {
        guard let environment = migrationController.environment else {
            return
        }

        let viewController = AccountViewController(account, environment: environment)
        pushViewController(viewController, animated: true)
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
