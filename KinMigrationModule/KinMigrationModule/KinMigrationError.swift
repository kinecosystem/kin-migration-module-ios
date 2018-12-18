//
//  KinMigrationError.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 18/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

//import KinCoreSDK
import KinSDK

public enum KinMigrationError: Error {
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

    /**
     Errors of type `Swift.Error` will be passed here.
     */
    case wrappedError (Error)
}

extension KinMigrationError: LocalizedError {
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
        case .wrappedError:
            return "Wrapped Error"
        }
    }
}

extension KinMigrationError {
    public init(error: Error) {
        self = .wrappedError(error)
    }

    //    public init(error: KinCoreSDK.KinError) {
    //        switch error {
    //        case .accountCreationFailed (let e):
    //            self = .accountCreationFailed(e)
    //        case .accountDeletionFailed (let e):
    //            self = .accountDeletionFailed(e)
    //        case .activationFailed (let e):
    //            self = .activationFailed(e)
    //        case .paymentFailed (let e):
    //            self = .paymentFailed(e)
    //        case .balanceQueryFailed (let e):
    //            self = .balanceQueryFailed(e)
    //        case .invalidAmount:
    //            self = .invalidAmount
    //        case .insufficientFunds:
    //            self = .insufficientFunds
    //        case .accountDeleted:
    //            self = .accountDeleted
    //        case .signingFailed:
    //            self = .signingFailed
    //        case .internalInconsistency:
    //            self = .internalInconsistency
    //        case .unknown:
    //            self = .unknown
    //        }
    //    }

    public init(error: KinSDK.KinError) {
        switch error {
        case .accountCreationFailed (let e):
            self = .accountCreationFailed(e)
        case .accountDeletionFailed (let e):
            self = .accountDeletionFailed(e)
        case .transactionCreationFailed (let e):
            self = .transactionCreationFailed(e)
        case .paymentFailed (let e):
            self = .paymentFailed(e)
        case .balanceQueryFailed (let e):
            self = .balanceQueryFailed(e)
        case .invalidAppId:
            self = .invalidAppId
        case .invalidAmount:
            self = .invalidAmount
        case .insufficientFunds:
            self = .insufficientFunds
        case .accountDeleted:
            self = .accountDeleted
        case .signingFailed:
            self = .signingFailed
        case .internalInconsistency:
            self = .internalInconsistency
        case .unknown:
            self = .unknown
        }
    }
}
