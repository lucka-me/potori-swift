//
//  Navigation.swift
//  Potori (iOS)
//
//  Created by Lucka on 21/1/2021.
//

import Combine
import SwiftUI

class NavigationModel: ObservableObject {
    
    class ViewLabel {
        static let dashboard = Label("view.dashboard", systemImage: "gauge")
        static let list = Label("view.list", systemImage: "list.bullet")
        #if os(iOS)
        static let preferences = Label("view.preferences", systemImage: "gearshape")
        #endif
    }
    
    enum View: Hashable {
        case dashboard
        case list
        #if os(iOS)
        case preference
        #endif
    }
    
    #if os(macOS)
    @Published var list: NominationList.Configuration = .init("view.dashboard.highlight.nominations", open: false)
    private var listCancellable: AnyCancellable? = nil
    #endif
    @Published var activeView: View? = .dashboard
    
    #if os(macOS)
    init() {
        listCancellable = $list.sink { value in
            if value.open {
                self.activeView = .list
            }
        }
    }
    #endif
}
