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
    let networkViewController = NetworkViewController()

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        networkViewController.testButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        networkViewController.mainButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)

        viewControllers = [networkViewController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Network View Controller

extension MainNavigationController {
    @objc
    private func buttonAction(_ button: UIButton) {
        // TODO: create the migration manager here and pass it to the account list vc, instead of account vc.
        let network: Network = button == networkViewController.mainButton ? .mainNet : .testNet
        pushViewController(AccountViewController(network: network), animated: true)
    }
}
