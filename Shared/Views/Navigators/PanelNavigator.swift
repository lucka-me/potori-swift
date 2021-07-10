//
//  PanelNavigator.swift
//  Potori
//
//  Created by Lucka on 21/1/2021.
//

import Combine
import SwiftUI

class PanelNavigator: ObservableObject {
    
    enum Tag: Hashable {
        case dashboard
        #if os(macOS)
        case list
        case map
        #else
        case preference
        #endif
    }
    
    class LabelView {
        static let dashboard = Label("view.dashboard", systemImage: "gauge")
        #if os(macOS)
        static let list = Label("view.list", systemImage: "list.bullet")
        static let map = Label("view.map", systemImage: "map")
        #else
        static let preferences = Label("view.preferences", systemImage: "gearshape")
        #endif
    }
    
    @Published var showMatchView: Bool = false
    @Published var actived: Tag = .dashboard
}
