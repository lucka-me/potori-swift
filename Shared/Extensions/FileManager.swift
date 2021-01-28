//
//  FileManager.swift
//  Potori
//
//  Created by Lucka on 28/1/2021.
//

import Foundation

extension FileManager {
    #if os(macOS)
    static let appGroupIdentifier = "labs.lucka.potori"
    #else
    static let appGroupIdentifier = "group.labs.lucka.potori"
    #endif
}
