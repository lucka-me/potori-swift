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
    
    mutating func removingFirst() -> Self {
        self.removeFirst()
        return self
    }
    
    func subString(
        of aString: String,
        options mask: CompareOptions = [],
        range searchRange: Range<Self.Index>? = nil,
        locale: Locale? = nil
    ) -> String? {
        guard
            let range = range(of: aString, options: mask, range: searchRange, locale: locale)
        else {
            return nil
        }
        return .init(self[range])
    }
}
