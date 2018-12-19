//
//  WrappedKinCoreAccount.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import KinCoreSDK
import StellarErrors

class WrappedKinCoreAccount: KinAccountProtocol {
    let account: KinCoreSDK.KinAccount

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

    init(_ kinAccount: KinCoreSDK.KinAccount) {
        self.account = kinAccount
    }

    func status() -> Promise<AccountStatus> {
        let promise = Promise<AccountStatus>()

        account.status()
            .then { accountStatus in
                promise.signal(accountStatus.mapToKinMigration)
            }
            .error { error in
                promise.signal(KinError(error: error))
        }

        return promise
    }

    func balance() -> Promise<Kin> {
        let promise = Promise<Kin>()

        account.balance()
            .then { kin in
                promise.signal(kin)
            }
            .error { error in
                promise.signal(KinError(error: error))
        }

        return promise
    }

    // MARK: Transaction

    func sendTransaction(to recipient: String, kin: Kin, memo: String?, whitelist: @escaping WhitelistClosure) -> Promise<TransactionId> {
        let promise = Promise<TransactionId>()

        account.sendTransaction(to: recipient, kin: kin, memo: memo)
            .then { transactionId in
                promise.signal(transactionId)
            }
            .error { error in
                promise.signal(KinError(error: error))
        }

        return promise
    }

    // MARK: Export

    func export(passphrase: String) throws -> String {
        do {
            return try account.export(passphrase: passphrase)
        }
        catch {
            throw KinError(error: error)
        }
    }

    // MARK: Watchers

    func watchCreation() throws -> Promise<Void> {
        do {
            let promise = Promise<Void>()

            try account.watchCreation()
                .then { _ in
                    promise.signal(Void())
                }
                .error { error in
                    promise.signal(KinError(error: error))
            }

            return promise
        }
        catch {
            throw KinError(error: error)
        }
    }

    func watchBalance(_ balance: Kin?) throws -> BalanceWatchProtocol {
        do {
            return WrappedKinCoreBalanceWatch(try account.watchBalance(balance))
        }
        catch {
            throw KinError(error: error)
        }
    }

    func watchPayments(cursor: String?) throws -> PaymentWatchProtocol {
        do {
            return WrappedKinCorePaymentWatch(try account.watchPayments(cursor: cursor))
        }
        catch {
            throw KinError(error: error)
        }
    }
}

extension KinCoreSDK.AccountStatus {
    fileprivate var mapToKinMigration: AccountStatus {
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
