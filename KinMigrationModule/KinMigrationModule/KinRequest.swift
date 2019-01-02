//
//  KinRequest.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 02/01/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import KinUtil

class KinRequest {
    private static let failedRetryChances = 3

    private let promise = Promise<Response>()
    private var urlSessionDataTask: URLSessionDataTask?

    init(_ urlRequest: URLRequest, retryChances: Int = failedRetryChances) {
        urlSessionDataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, _, error) in
            guard let strongSelf = self else {
                return
            }

            if let error = error {
                if retryChances > 0 {
                    KinRequest(urlRequest, retryChances: retryChances - 1).resume()
                        .then { strongSelf.promise.signal($0) }
                        .error { strongSelf.promise.signal($0) }
                }
                else {
                    strongSelf.promise.signal(KinMigrationError.responseFailed(error))
                }
                return
            }

            guard let data = data else {
                strongSelf.promise.signal(KinMigrationError.responseEmpty)
                return
            }

            do {
                strongSelf.promise.signal(try JSONDecoder().decode(Response.self, from: data))
            }
            catch {
                strongSelf.promise.signal(KinMigrationError.decodingFailed(error))
            }
        }
    }

    func resume() -> Promise<Response> {
        urlSessionDataTask?.resume()
        return promise
    }
}

extension KinRequest {
    struct Response: Codable {
        let code: Int
        let message: String
    }

    /**
     Migration Service Response Code

     - SeeAlso: https://github.com/kinecosystem/migration-server
     */
    enum MigrateCode: Int {
        case success                = 200
        case accountNotBurned       = 4001
        case accountAlreadyMigrated = 4002
        case invalidPublicAddress   = 4003
        case accountNotFound        = 4041
    }
}
