//
//  KinMigrationError.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 02/01/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

public enum KinMigrationError: Error {
    case invalidNetwork
    case invalidMigrationURL
    case missingDelegate
    case responseEmpty
    case responseFailed (Error)
    case decodingFailed (Error)
    case migrateFailed (code: Int, message: String)
}

extension KinMigrationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidNetwork:
            return "The provided `network` is invalid."
        case .invalidMigrationURL:
            return "The provided `migrateBaseURL` is invalid."
        case .missingDelegate:
            return "The `delegate` was not set."
        case .responseEmpty:
            return "Response was empty."
        case .responseFailed:
            return "Response failed."
        case .decodingFailed:
            return "Decoding response failed."
        case .migrateFailed:
            return "Migrating account failed."
        }
    }
}
