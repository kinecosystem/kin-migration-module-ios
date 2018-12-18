//
//  WrappedKinSDKAccount.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import KinSDK

class WrappedKinSDKAccount: KinAccountProtocol {
    let account: KinSDK.KinAccount

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

    init(_ kinAccount: KinSDK.KinAccount) {
        self.account = kinAccount
    }

    func status() -> Promise<AccountStatus> {
        return account.status().then { return Promise($0.mapToKinMigration) }
    }

    func balance() -> Promise<Kin> {
        let e = KinSDK.KinError.balanceQueryFailed(StellarError.missingAccount)
        return Promise(KinError(error: e))
//        return account.balance()
    }

    // MARK: Transaction

    func sendTransaction(to recipient: String, kin: Kin, memo: String?, whitelist: @escaping WhitelistClosure) -> Promise<TransactionId> {
        let promise: Promise<TransactionId> = Promise()

        account.generateTransaction(to: recipient, kin: kin, memo: memo)
            .then { transactionEnvelope -> Promise<TransactionEnvelope> in
                return whitelist(transactionEnvelope)
            }
            .then { [weak self] transactionEnvelope -> Promise<TransactionId> in
                guard let strongSelf = self else {
                    return promise.signal(error: KinError.internalInconsistency)
                }

                return strongSelf.account.sendTransaction(transactionEnvelope)
            }
            .then { transactionId -> Void in
                promise.signal(transactionId)
            }
            .error { error in
                promise.signal(error)
        }

        return promise
    }

    // MARK: Export

    func export(passphrase: String) throws -> String {
        return try account.export(passphrase: passphrase)
    }

    // MARK: Watchers

    func watchCreation() throws -> Promise<Void> {
        return try account.watchCreation()
    }

    func watchBalance(_ balance: Kin?) throws -> BalanceWatchProtocol {
        return WrappedKinSDKBalanceWatch(try account.watchBalance(balance))
    }

    func watchPayments(cursor: String?) throws -> PaymentWatchProtocol {
        return WrappedKinSDKPaymentWatch(try account.watchPayments(cursor: cursor))
    }
}

extension KinSDK.AccountStatus {
    fileprivate var mapToKinMigration: AccountStatus {
        switch self {
        case .created:
            return .created
        case .notCreated:
            return .notCreated
        }
    }
}
