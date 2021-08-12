//
//  String.swift
//  Potori
//
//  Created by Lucka on 18/5/2021.
//

import Foundation

extension String {
    
    init?(base64Encoded: String) {
        let encoded = base64Encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: encoded, options: .ignoreUnknownCharacters) else {
            return nil
        }
        self.init(data: data, encoding: .utf8)
    }
    
    subscript(range: NSRange) -> Substring? {
        guard let bounded = Range(range, in: self) else { return nil }
        return self[bounded]
    }

    func first(matches regularExpression: NSRegularExpression) -> [ Substring? ]? {
        guard let result = regularExpression.firstMatch(in: self, range: entire) else {
            return nil
        }
        return (0 ..< result.numberOfRanges).map { self[result.range(at: $0)] }
    }
    
    func first(matches regularExpression: NSRegularExpression, at index: Int) -> Substring? {
        guard
            index >= 0,
            let result = regularExpression.firstMatch(in: self, range: entire),
            index < result.numberOfRanges
        else {
            return nil
        }
        return self[result.range(at: index)]
    }
    
    private var entire: NSRange {
        .init(startIndex..., in: self)
    }
}
