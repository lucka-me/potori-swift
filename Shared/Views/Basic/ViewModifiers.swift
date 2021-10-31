//
//  ViewModifiers.swift
//  ViewModifiers
//
//  Created by Lucka on 28/7/2021.
//

import SwiftUI

extension View {
    @inlinable func card(color: Color = .clear, radius: CGFloat = 12) -> some View {
        self
            .padding(radius)
            .background(color == .clear ? .thickMaterial : .ultraThinMaterial)
            .background(color)
            .mask {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
            }
    }
}
