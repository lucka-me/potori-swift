//
//  Navigation.swift
//  Potori (iOS)
//
//  Created by Lucka on 21/1/2021.
//

import Combine
import SwiftUI

class Navigation: ObservableObject {
    
    enum View: Hashable {
        case dashboard
        case list
        #if os(iOS)
        case preference
        #endif
    }
    
    struct OpenNominationsConfiguration {
        let title: LocalizedStringKey
        let predicate: NSPredicate?
        let selection: String?

        #if os(macOS)
        let view: View?
        #endif
        
        init(
            _ title: LocalizedStringKey,
            _ predicate: NSPredicate? = nil,
            _ selection: String? = nil,
            view: View? = nil
        ) {
            self.title = title
            self.predicate = predicate
            self.selection = selection
            #if os(macOS)
            self.view = view
            #endif
        }
    }
    
    class ViewLabel {
        static let dashboard = Label("view.dashboard", systemImage: "gauge")
        static let list = Label("view.list", systemImage: "list.bullet")
        #if os(iOS)
        static let preferences = Label("view.preferences", systemImage: "gearshape")
        #endif
    }
    
    #if os(macOS)
    @Published var openNominations: OpenNominationsConfiguration = .init("view.dashboard.highlight.nominations")
    private var openNominationsCancellable: AnyCancellable? = nil
    #endif
    @Published var activeView: View? = .dashboard
    
    #if os(macOS)
    init() {
        openNominationsCancellable = $openNominations.sink { value in
            if let solidView = value.view {
                self.activeView = solidView
            }
        }
    }
    #endif
}
