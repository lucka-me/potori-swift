//
//  Label.swift
//  Potori
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

extension Label where Title == Text, Icon == Image {
    
    #if os(macOS)
    static var dashboard: some View {
        Label("view.dashboard", systemImage: "gauge")
    }
    
    static var list: some View {
        Label("view.list", systemImage: "list.bullet")
    }
    
    static var map: some View {
        Label("view.map", systemImage: "map")
    }
    #endif
    
    #if os(iOS)
    static var preferences: Label {
        Label("view.preferences", systemImage: "gear")
    }
    #endif
    
    static var dismiss: Label {
        Label("action.dismiss", systemImage: "xmark")
    }
}
