//
//  AsyncImage.swift
//  Potori
//
//  Created by Lucka on 4/7/2021.
//

import SwiftUI

extension AsyncImage {
    init(url string: String, resizable: Bool = true, placeholder: Color = .gray) where Content == _ConditionalContent<Image, Color> {
        self.init(url: URL(string: string)) { image in
            if resizable {
                return image.resizable()
            } else {
                return image
            }
        } placeholder: {
            placeholder
        }
    }
}
