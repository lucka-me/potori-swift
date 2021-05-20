//
//  Array.swift
//  Potori
//
//  Created by Lucka on 20/5/2021.
//

import Foundation

extension Array {

    mutating func popFirst() -> Self.Element? {
        guard let element = first else {
            return nil
        }
        removeFirst()
        return element
    }
}
