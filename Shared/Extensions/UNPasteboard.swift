//
//  UNPasteboard.swift
//  Potori
//
//  Created by Lucka on 4/7/2021.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(macOS)
typealias UNPasteboard = NSPasteboard
#else
typealias UNPasteboard = UIPasteboard
#endif

extension UNPasteboard {
    #if os(macOS)
    var string: String? {
        string(forType: .string)
    }
    #endif
}
