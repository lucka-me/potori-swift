//
//  BlurVisualEffectView.swift
//  macOS
//
//  Created by Lucka on 29/5/2021.
//

import SwiftUI

struct BlurVisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        .init()
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.blendingMode = .withinWindow
    }
}
