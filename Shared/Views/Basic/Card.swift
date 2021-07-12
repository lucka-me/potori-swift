//
//  Card.swift
//  Potori
//
//  Created by Lucka on 6/5/2021.
//

import SwiftUI

struct Card<Content: View>: View {
    
    private let radius: CGFloat
    private let alignment: HorizontalAlignment
    private let content: () -> Content
    
    init(
        radius: CGFloat = 12,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.radius = radius
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: alignment, content: content)
            .padding(radius)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
struct Card_Previews: PreviewProvider {
    static var previews: some View {
        Card {
            Label("Sample", systemImage: "face")
        }
    }
}
#endif
