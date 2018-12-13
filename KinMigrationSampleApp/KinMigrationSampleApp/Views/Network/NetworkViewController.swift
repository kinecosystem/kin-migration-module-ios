//
//  NetworkViewController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 13/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit

class NetworkViewController: UIViewController {
    let testButton = createButton("TestNet", color: .blue)
    let mainButton = createButton("MainNet", color: .orange)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(testButton)
        testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30).isActive = true

        view.addSubview(mainButton)
        mainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mainButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 30).isActive = true
    }

    private static func createButton(_ title: String, color: UIColor) -> UIButton {
        let button = UIButton()
        button.backgroundColor = color
        button.setTitle(title, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
