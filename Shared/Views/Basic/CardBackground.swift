//
//  CardBackground.swift
//  Potori
//
//  Created by Lucka on 24/1/2021.
//

import SwiftUI

struct CardBackground: View {
    
    private let radius: CGFloat
    
    init(radius: CGFloat = 10) {
        self.radius = radius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.gray.opacity(0.15))
    }
}

struct CardBackground_Previews: PreviewProvider {
    static var previews: some View {
        CardBackground()
    }
}
