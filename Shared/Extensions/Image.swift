//
//  Image.swift
//  Potori
//
//  Created by Lucka on 6/5/2021.
//

import SwiftUI

#if os(macOS)
typealias UNImage = NSImage
#else
typealias UNImage = UIImage
#endif

extension Image {
    
    fileprivate init(unImage: UNImage) {
        #if os(macOS)
        self.init(nsImage: unImage)
        #else
        self.init(uiImage: unImage)
        #endif
    }
    
    init?(data: Data?) {
        guard
            let solidData = data,
            let unImage = UNImage(data: solidData)
        else {
            return nil
        }
        self.init(unImage: unImage)
    }
}
