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
        static var dashboard: some View {
            Label("view.dashboard", systemImage: "gauge")
        }
        #if os(macOS)
        static var list: some View {
            Label("view.list", systemImage: "list.bullet")
        }
        static var map: some View {
            Label("view.map", systemImage: "map")
        }
        #else
        static var preferences: some View {
            Label("view.preferences", systemImage: "gear")
        }
        #endif
    }
    
    @Published var showMatchView: Bool = false
    #if os(macOS)
    @Published var actived: Tag? = .dashboard
    #else
    @Published var actived: Tag = .dashboard
    #endif
}
