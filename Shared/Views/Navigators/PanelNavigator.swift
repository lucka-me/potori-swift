//
//  PanelNavigator.swift
//  Potori
//
//  Created by Lucka on 21/1/2021.
//

import Combine
import SwiftUI

class PanelNavigator: ObservableObject {
    
    #if os(macOS)
    enum Tag: Hashable {
        case dashboard
        case list
        case map
    }
    
    class LabelView {
        static var dashboard: some View {
            Label("view.dashboard", systemImage: "gauge")
        }
        
        static var list: some View {
            Label("view.list", systemImage: "list.bullet")
        }
        static var map: some View {
            Label("view.map", systemImage: "map")
        }
    }
    #endif
    
    @Published var showMatchView: Bool = false
    #if os(macOS)
    @Published var actived: Tag? = .dashboard
    #endif
}
