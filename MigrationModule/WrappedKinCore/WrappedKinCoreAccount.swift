//
//  WrappedKinCoreAccount.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import KinCoreSDK

internal class WrappedKinCoreAccount: KinAccountProtocol {
    let account: KinCoreSDK.KinAccount

    init(_ kinAccount: KinCoreSDK.KinAccount) {
        self.account = kinAccount
    }

    func export(passphrase: String) throws -> String {
        return try account.export(passphrase: passphrase)
    }

    func status() -> Promise<AccountStatus> {
        return account.status().then { return Promise($0.mapToKinMigration) }
    }

    func balance() -> Promise<Kin> {
        return account.balance()
    }

    var publicAddress: String {
        return account.publicAddress
    }

    var extra: Data? {
        get {
            return account.extra
        }
        set {
            account.extra = newValue
        }
    }

    // MARK:

    func sendTransaction(to recipient: String, kin: Kin, memo: String?, whitelist: @escaping WhitelistClosure) -> Promise<TransactionId> {
        return account.sendTransaction(to: recipient, kin: kin, memo: memo)
    }

    // MARK: Watchers

    func watchCreation() throws -> Promise<Void> {
        return try account.watchCreation()
    }

    func watchBalance(_ balance: Kin?) throws -> BalanceWatchProtocol {
        return WrappedKinCoreBalanceWatch(try account.watchBalance(balance))
    }

    func watchPayments(cursor: String?) throws -> PaymentWatchProtocol {
        return WrappedKinCorePaymentWatch(try account.watchPayments(cursor: cursor))
    }
}

internal extension KinCoreSDK.AccountStatus {
    var mapToKinMigration: AccountStatus {
        switch self {
        case .notCreated:
            return .notCreated
        case .notActivated:
            return .notActivated
        case .activated:
            return .created
        }
    }
}
