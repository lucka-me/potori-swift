//
//  ViewStyles.swift
//  Potori
//
//  Created by Lucka on 18/5/2021.
//

import SwiftUI

struct FixedSizeIconLabelStyle: LabelStyle {
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
                .frame(width: iconSize, height: iconSize, alignment: .center)
            configuration.title
                .lineLimit(1)
        }
    }
    
    private var iconSize: CGFloat {
        switch dynamicTypeSize {
            case .xSmall: return 16
            case .small: return 21
            case .medium: return 24
            case .large: return 28
            case .xLarge: return 32
            case .xxLarge: return 36
            case .xxxLarge: return 40
            case .accessibility1: return 48
            case .accessibility2: return 52
            case .accessibility3: return 60
            case .accessibility4: return 66
            case .accessibility5: return 72
            default: return 24
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
