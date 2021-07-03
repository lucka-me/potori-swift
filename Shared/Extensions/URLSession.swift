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
        cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad,
        completionHandler: @escaping (Data?) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completionHandler(nil)
            return
        }
        let request = URLRequest(url: url, cachePolicy: cachePolicy)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            completionHandler(data)
        }
        .resume()
    }
}
