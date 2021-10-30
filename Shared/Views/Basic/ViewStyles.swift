//
//  ViewStyles.swift
//  Potori
//
//  Created by Lucka on 18/5/2021.
//

import SwiftUI

struct FixedSizeIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .aspectRatio(1, contentMode: .fit)
            configuration.title
                .lineLimit(1)
        }
    }
}

extension LabelStyle where Self == FixedSizeIconLabelStyle {
    static var fixedSizeIcon: FixedSizeIconLabelStyle {
        .init()
    }
}

struct PlainButtonToggleStyle : ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            configuration.label
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == PlainButtonToggleStyle {
    static var plainButton: PlainButtonToggleStyle {
        .init()
    }
}
