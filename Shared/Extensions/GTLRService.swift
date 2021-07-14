//
//  GTLRService.swift
//  Potori
//
//  Created by Lucka on 14/7/2021.
//

import GoogleAPIClientForRESTCore

extension GTLRService {
    public func execute<Query: GTLRQueryProtocol>(_ query: Query) async throws -> Any? {
        return try await withCheckedThrowingContinuation { continuation in
            executeQuery(query) { _, response, error in
                if let solidError = error {
                    continuation.resume(throwing: solidError)
                    return
                }
                continuation.resume(returning: response)
            }
        }
    }
}
