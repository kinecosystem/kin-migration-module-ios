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
public typealias TransactionId = KinSDK.TransactionId
public typealias TransactionEnvelope = KinSDK.TransactionEnvelope
public typealias WhitelistEnvelope = KinSDK.WhitelistEnvelope

public typealias LinkBag = KinUtil.LinkBag
public typealias Promise = KinUtil.Promise
public typealias Observable<T> = KinUtil.Observable<T>

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

internal struct KinResponse<T: Codable>: Codable {
    let success: T
}




// TODO: move to own class after fixing compiler issue

import KinCoreSDK
import StellarErrors

public enum KinError: Error {
    // Kin Errors
    case accountCreationFailed (Error)
    case accountDeletionFailed (Error)
    case transactionCreationFailed (Error) // KinSDK Only
    case activationFailed (Error)          // KinCore Only
    case paymentFailed (Error)
    case balanceQueryFailed (Error)
    case invalidAppId                      // KinSDK Only
    case invalidAmount
    case insufficientFunds
    case accountDeleted
    case signingFailed
    case internalInconsistency
    case unknown

    // Stellar Errors
    case memoTooLong (Any?)
    case missingAccount
    case missingPublicKey
    case missingHash
    case missingSequence
    case missingBalance
    case missingSignClosure
    case urlEncodingFailed
    case dataEncodingFailed
    case dataDencodingFailed
    case destinationNotReadyForAsset (Error)
    case unknownError (Any?)

    // Other Errors
    case wrappedError (Error)
}

extension KinError: LocalizedError {
    /// :nodoc:
    public var errorDescription: String? {
        switch self {
        case .accountCreationFailed:
            return "Account creation failed"
        case .accountDeletionFailed:
            return "Account deletion failed"
        case .transactionCreationFailed:
            return "Transaction creation failed"
        case .activationFailed:
            return "Account activation failed"
        case .paymentFailed:
            return "Payment failed"
        case .balanceQueryFailed:
            return "Balance query failed"
        case .invalidAppId:
            return "Invalid app id"
        case .invalidAmount:
            return "Invalid Amount"
        case .insufficientFunds:
            return "Insufficient funds"
        case .accountDeleted:
            return "Account Deleted"
        case .signingFailed:
            return "Signing Failed"
        case .internalInconsistency:
            return "Internal Inconsistency"
        case .unknown:
            return "Unknown Error"

        case .memoTooLong:
            return "Memo Too Long"
        case .missingAccount:
            return "Missing Account"
        case .missingPublicKey:
            return "Missing Public Key"
        case .missingHash:
            return "Missing Hash"
        case .missingSequence:
            return "Missing Sequence"
        case .missingBalance:
            return "Missing Balance"
        case .missingSignClosure:
            return "Missing Sign Closure"
        case .urlEncodingFailed:
            return "URL Encoding Failed"
        case .dataEncodingFailed:
            return "Data Encoding Failed"
        case .dataDencodingFailed:
            return "Data Dencoding Failed"
        case .destinationNotReadyForAsset:
            return "Destination Not Ready For Asset"
        case .unknownError:
            return "Unknown Error"

        case .wrappedError:
            return "Wrapped Error"
        }
    }
}

extension KinError {
    public init(error: Error) {
        self = KinError.mapError(error) ?? .wrappedError(error)
    }

    private static func mapError(_ error: Error) -> KinError? {
        if let error = error as? StellarErrors.StellarError {
            return stellarError(error)
        }
        else if let error = error as? KinSDK.StellarError {
            return stellarError(error)
        }
        else if let error = error as? KinCoreSDK.KinError {
            return kinError(error)
        }
        else if let error = error as? KinSDK.KinError {
            return kinError(error)
        }
        else {
            return nil
        }
    }

    private static func kinError(_ error: KinCoreSDK.KinError) -> KinError {
        switch error {
        case .accountCreationFailed (let e):
            return KinError.mapError(e) ?? .accountCreationFailed(e)
        case .accountDeletionFailed (let e):
            return KinError.mapError(e) ?? .accountDeletionFailed(e)
        case .activationFailed (let e):
            return KinError.mapError(e) ?? .activationFailed(e)
        case .paymentFailed (let e):
            return KinError.mapError(e) ?? .paymentFailed(e)
        case .balanceQueryFailed (let e):
            return KinError.mapError(e) ?? .balanceQueryFailed(e)
        case .invalidAmount:
            return .invalidAmount
        case .insufficientFunds:
            return .insufficientFunds
        case .accountDeleted:
            return .accountDeleted
        case .signingFailed:
            return .signingFailed
        case .internalInconsistency:
            return .internalInconsistency
        case .unknown:
            return .unknown
        }
    }

    private static func kinError(_ error: KinSDK.KinError) -> KinError {
        switch error {
        case .accountCreationFailed (let e):
            return KinError.mapError(e) ?? .accountCreationFailed(e)
        case .accountDeletionFailed (let e):
            return KinError.mapError(e) ?? .accountDeletionFailed(e)
        case .transactionCreationFailed (let e):
            return KinError.mapError(e) ?? .transactionCreationFailed(e)
        case .paymentFailed (let e):
            return KinError.mapError(e) ?? .paymentFailed(e)
        case .balanceQueryFailed (let e):
            return KinError.mapError(e) ?? .balanceQueryFailed(e)
        case .invalidAppId:
            return .invalidAppId
        case .invalidAmount:
            return .invalidAmount
        case .insufficientFunds:
            return .insufficientFunds
        case .accountDeleted:
            return .accountDeleted
        case .signingFailed:
            return .signingFailed
        case .internalInconsistency:
            return .internalInconsistency
        case .unknown:
            return .unknown
        }
    }

    private static func stellarError(_ error: StellarErrors.StellarError) -> KinError {
        switch error {
        case .memoTooLong (let object):
            return .memoTooLong(object)
        case .missingAccount:
            return .missingAccount
        case .missingPublicKey:
            return .missingPublicKey
        case .missingHash:
            return .missingHash
        case .missingSequence:
            return .missingSequence
        case .missingBalance:
            return .missingBalance
        case .missingSignClosure:
            return .missingSignClosure
        case .urlEncodingFailed:
            return .urlEncodingFailed
        case .dataEncodingFailed:
            return .dataEncodingFailed
        case .signingFailed:
            return .signingFailed
        case .destinationNotReadyForAsset (let e, _):
            return KinError.mapError(e) ?? .destinationNotReadyForAsset(e)
        case .unknownError (let object):
            return .unknownError(object)
        case .internalInconsistency:
            return .internalInconsistency
        }
    }

    private static func stellarError(_ error: KinSDK.StellarError) -> KinError {
        switch error {
        case .memoTooLong (let object):
            return .memoTooLong(object)
        case .missingAccount:
            return .missingAccount
        case .missingPublicKey:
            return .missingPublicKey
        case .missingHash:
            return .missingHash
        case .missingSequence:
            return .missingSequence
        case .missingBalance:
            return .missingBalance
        case .missingSignClosure:
            return .missingSignClosure
        case .urlEncodingFailed:
            return .urlEncodingFailed
        case .dataEncodingFailed:
            return .dataEncodingFailed
        case .dataDencodingFailed:
            return .dataDencodingFailed
        case .signingFailed:
            return .signingFailed
        case .destinationNotReadyForAsset (let e):
            return KinError.mapError(e) ?? .destinationNotReadyForAsset(e)
        case .unknownError (let object):
            return .unknownError(object)
        case .internalInconsistency:
            return .internalInconsistency
        }
    }
}
