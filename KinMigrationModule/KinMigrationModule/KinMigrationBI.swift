//
//  KinMigrationBI.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 15/01/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

public enum KinMigrationBIBurnReason {
    case noAccount
    case noTrustline
    case burned
    case alreadyBurned
}

public enum KinMigrationBIMigrateReason {
    case noAccount
    case migrated
    case alreadyMigrated
}

public enum KinMigrationBIReadyReason {
    case noAccountToMigrate
    case apiCheck
    case migrated
    case alreadyMigrated
}

public protocol KinMigrationBIDelegate: NSObjectProtocol {
    func kinMigrationStart()
    func kinMigrationReady(reason: KinMigrationBIReadyReason, version: KinVersion)
    func kinMigrationFailed(error: Error)

    func kinMigrationRequestVersionStart()
    func kinMigrationRequestVersionSuccess(version: KinVersion)
    func kinMigrationRequestVersionFailed(error: Error)

    func kinMigrationBurnStart(publicAddress: String)
    func kinMigrationBurnSuccess(reason: KinMigrationBIBurnReason, publicAddress: String)
    func kinMigrationBurnFailed(error: Error, publicAddress: String)

    func kinMigrationRequestAccountMigrationStart(publicAddress: String)
    func kinMigrationRequestAccountMigrationSuccess(reason: KinMigrationBIMigrateReason, publicAddress: String)
    func kinMigrationRequestAccountMigrationFailed(error: Error, publicAddress: String)
}
