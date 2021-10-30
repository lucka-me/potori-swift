//
//  FixedSizeIconLabelStyle.swift
//  Potori
//
//  Created by Lucka on 18/5/2021.
//

import SwiftUI

struct FixedSizeIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { proxy in
            HStack(alignment: .firstTextBaseline) {
                configuration.icon
                    .frame(width: proxy.size.height, height: proxy.size.height, alignment: .center)
                configuration.title
                    .lineLimit(1)
            }
        }
    }
}

extension LabelStyle where Self == FixedSizeIconLabelStyle {
    static var fixedSizeIcon: FixedSizeIconLabelStyle {
        .init()
    }
}
