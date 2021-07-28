//
//  ViewModifiers.swift
//  ViewModifiers
//
//  Created by Lucka on 28/7/2021.
//

import SwiftUI

extension View {
    @inlinable func card(radius: CGFloat = 12) -> some View {
        self
            .padding(radius)
            .background(
                .thickMaterial,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
    }
    
    @ViewBuilder
    @inlinable func appendSpacers(before: Bool = true, after: Bool = true) -> some View {
        if before {
            Spacer(minLength: 0)
        }
        self
        if after {
            Spacer(minLength: 0)
        }
    }
}
