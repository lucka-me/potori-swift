//
//  PanelNavigator.swift
//  Potori
//
//  Created by Lucka on 21/1/2021.
//

import Combine
import SwiftUI

#if os(macOS)
class PanelNavigator: ObservableObject {

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
    
    @Published var actived: Tag? = .dashboard
}
#endif
