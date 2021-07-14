//
//  GTLRService.swift
//  Potori
//
//  Created by Lucka on 14/7/2021.
//

import GoogleAPIClientForRESTCore

extension GTLRService {
    enum ErrorType: Error {
        case notAuthorized
        case unableToConvertResponse
    }
}

extension GTLRService {
    
    public func execute<Query: GTLRQueryProtocol>(_ query: Query) {
        executeQuery(query)
    }
    
    public func execute<Query: GTLRQueryProtocol, Response>(_ query: Query) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            executeQuery(query) { _, response, error in
                if let solidError = error {
                    continuation.resume(throwing: solidError)
                    return
                }
                guard let typedResponse = response as? Response else {
                    continuation.resume(throwing: ErrorType.unableToConvertResponse)
                    return
                }
                continuation.resume(returning: typedResponse)
            }
        }
    }
}
