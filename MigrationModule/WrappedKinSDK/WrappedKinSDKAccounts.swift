//
//  WrappedKinSDKAccounts.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import KinSDK

internal class WrappedKinSDKAccounts: KinAccountsProtocol {
    let accounts: KinSDK.KinAccounts

    init(_ kinAccounts: KinSDK.KinAccounts) {
        self.accounts = kinAccounts
    }

    // MARK: Wrapped Accounts

    private var wrappedAccounts: [WrappedKinSDKAccount] = []

    func wrappedAccount(_ account: KinSDK.KinAccount?) -> WrappedKinSDKAccount? {
        if let account = account {
            return wrappedAccounts.first { $0.account.publicAddress == account.publicAddress }
        }
        return nil
    }

    func wrappedAccountIndex(_ account: KinSDK.KinAccount?) -> Int? {
        if let account = account {
            return wrappedAccounts.firstIndex { $0.account.publicAddress == account.publicAddress }
        }
        return nil
    }

    func addWrappedAccount(_ account: KinSDK.KinAccount) -> WrappedKinSDKAccount {
        let wrappedAccount = WrappedKinSDKAccount(account)
        wrappedAccounts.append(wrappedAccount)
        return wrappedAccount
    }

    func deleteWrappedAccount(_ account: KinSDK.KinAccount) {
        if let index = wrappedAccountIndex(account) {
            wrappedAccounts.remove(at: index)
        }
    }

    // MARK:

    subscript(index: Int) -> KinAccountProtocol? {
        return wrappedAccount(accounts[index])
    }

    var count: Int {
        return accounts.count
    }

    var first: KinAccountProtocol? {
        return wrappedAccount(accounts.first)
    }

    var last: KinAccountProtocol? {
        return wrappedAccount(accounts.last)
    }

    func makeIterator() -> AnyIterator<KinAccountProtocol?> {
        let wrappedAccounts = accounts.makeIterator().map { wrappedAccount($0) }
        var index = 0

        return AnyIterator {
            let wrappedAccount = wrappedAccounts[index]

            index += 1

            return wrappedAccount
        }
    }

    var startIndex: Int {
        return accounts.startIndex
    }

    var endIndex: Int {
        return accounts.endIndex
    }
}
