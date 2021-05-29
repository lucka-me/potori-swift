//
//  BlurVisualEffectView.swift
//  iOS
//
//  Created by Lucka on 29/5/2021.
//

import SwiftUI

struct BlurVisualEffectView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        .init()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: .prominent)
    }
}
