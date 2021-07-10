//
//  FixedWidthIconLabelStyle.swift
//  Potori
//
//  Created by Lucka on 18/5/2021.
//

import SwiftUI

struct FixedWidthIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline) {
            configuration.icon
                .frame(width: 24, alignment: .center)
            configuration.title
        }
    }
}

extension LabelStyle where Self == FixedWidthIconLabelStyle {
    static var fixedWidthIcon: FixedWidthIconLabelStyle {
        .init()
    }
}
