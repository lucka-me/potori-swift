//
//  FileManager.swift
//  Potori
//
//  Created by Lucka on 28/1/2021.
//

import Foundation

extension FileManager {
    #if os(macOS)
    static let appGroupIdentifier = "moe.lucka.potori"
    #else
    static let appGroupIdentifier = "group.moe.lucka.potori"
    #endif
}
