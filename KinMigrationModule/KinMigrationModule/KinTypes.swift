//
//  KinTypes.swift
//  multi
//
//  Created by Corey Werner on 04/12/2018.
//  Copyright © 2018 Corey Werner. All rights reserved.
//

import KinSDK
import KinUtil

public typealias Kin = KinSDK.Kin
public typealias AppId = KinSDK.AppId
public typealias Network = KinSDK.Network
public typealias Node = KinSDK.Stellar.Node
public typealias Promise = KinUtil.Promise
public typealias TransactionId = KinSDK.TransactionId
public typealias TransactionEnvelope = KinSDK.TransactionEnvelope
public typealias WhitelistEnvelope = KinSDK.WhitelistEnvelope

public protocol KinClientProtocol {
    var url: URL { get }
    var network: Network { get }
    var accounts: KinAccountsProtocol { get }
    func addAccount() throws -> KinAccountProtocol
    func deleteAccount(at index: Int) throws
    func importAccount(_ jsonString: String, passphrase: String) throws -> KinAccountProtocol
    func deleteKeystore()
}

public protocol KinAccountsProtocol {
    subscript(_ index: Int) -> KinAccountProtocol? { get }
    var count: Int { get }
    var first: KinAccountProtocol? { get }
    var last: KinAccountProtocol? { get }
    var startIndex: Int { get }
    var endIndex: Int { get }
    func makeIterator() -> AnyIterator<KinAccountProtocol>
}

public protocol KinAccountProtocol {
    var publicAddress: String { get }
    var extra: Data? { get set }
    func status() -> Promise<AccountStatus>
    func balance() -> Promise<Kin>
    func sendTransaction(to recipient: String, kin: Kin, memo: String?, whitelist: @escaping WhitelistClosure) -> Promise<TransactionId>
    func export(passphrase: String) throws -> String
    func watchCreation() throws -> Promise<Void>
    func watchBalance(_ balance: Kin?) throws -> BalanceWatchProtocol
    func watchPayments(cursor: String?) throws -> PaymentWatchProtocol
}

public typealias WhitelistClosure = (TransactionEnvelope)->(Promise<TransactionEnvelope>)

public enum AccountStatus: Int {
    case notCreated
    case created
    // KinCore only
    case notActivated
}

public protocol BalanceWatchProtocol {
    var emitter: StatefulObserver<Kin> { get }
}

public protocol PaymentWatchProtocol {
    var emitter: Observable<PaymentInfoProtocol> { get }
    var cursor: String? { get }
}

public protocol PaymentInfoProtocol {
    var createdAt: Date { get }
    var credit: Bool { get }
    var debit: Bool { get }
    var source: String { get }
    var hash: String { get }
    var amount: Kin { get }
    var destination: String { get }
    var memoText: String? { get }
    var memoData: Data? { get }
}
