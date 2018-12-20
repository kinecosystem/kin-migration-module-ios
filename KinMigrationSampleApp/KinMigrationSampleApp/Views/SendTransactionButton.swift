//
//  SendTransactionButton.swift
//  KinMigrationSampleApp
//
//  Created by Corey Werner on 20/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit

class SendTransactionButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setTitle("Send", for: .normal)
        setTitle("Sending...", for: .disabled)
        setTitle("Sent", for: .selected)
        setTitle("Sending Failed", for: [.disabled, .selected])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sendState: SendState = .ready {
        didSet {
            switch sendState {
            case .ready:
                isEnabled = true
                isSelected = false
            case .sending:
                isEnabled = false
                isSelected = false
            case .sent:
                isEnabled = true
                isSelected = true
            case .failed:
                isEnabled = false
                isSelected = true
            }
        }
    }
}

extension SendTransactionButton {
    enum SendState {
        case ready
        case sending
        case sent
        case failed
    }
}
