//
//  KinMigrationError.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 02/01/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

public enum KinMigrationError: Error {
    case missingDelegate
    case missingNodeURL
    case responseEmpty
    case responseFailed (Error)
    case decodingFailed (Error)
    case migrateFailed (code: Int, message: String)
}

extension KinMigrationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingDelegate:
            return "The `delegate` was not set."
        case .missingNodeURL:
            return "A custom network was used without setting the `nodeURL`."
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
