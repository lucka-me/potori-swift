//
//  URLSession.swift
//  Potori
//
//  Created by Lucka on 6/5/2021.
//

import Foundation

extension URLSession {
    
    func dataTask(
        with urlString: String,
        cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy
    ) async -> Data? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        let request = URLRequest(url: url, cachePolicy: cachePolicy)
        return await withCheckedContinuation { continuation in
            dataTask(with: request) { data, _, _ in
                continuation.resume(returning: data)
            }
            .resume()
        }
    }
}
