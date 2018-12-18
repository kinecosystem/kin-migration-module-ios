//
//  NetworkViewController.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 13/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit

class NetworkViewController: UIViewController {
    let testV2Button = createButton("TestNet KinCore", color: .blue)
    let testV3Button = createButton("TestNet KinSDK", color: .blue)
    let mainButton = createButton("MainNet", color: .orange)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let layoutGuide = UILayoutGuide()
        view.addLayoutGuide(layoutGuide)
        layoutGuide.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor).isActive = true

        view.addSubview(testV2Button)
        testV2Button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        testV2Button.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true

        view.addSubview(testV3Button)
        testV3Button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        testV3Button.topAnchor.constraint(equalTo: testV2Button.bottomAnchor, constant: 20).isActive = true

        view.addSubview(mainButton)
        mainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mainButton.topAnchor.constraint(equalTo: testV3Button.bottomAnchor, constant: 20).isActive = true
        mainButton.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true
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
