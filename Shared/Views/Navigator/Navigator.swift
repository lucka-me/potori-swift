//
//  Navigator.swift
//  macOS
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

class Navigator: ObservableObject {

    #if os(macOS)
    enum Tag: Hashable {
        case dashboard
        case list
        case map
    }
    #endif
    
    struct Configuration {
        let title: LocalizedStringKey
        let predicate: NSPredicate?
        
        init(
            _ title: LocalizedStringKey = "view.dashboard.highlights.all",
            predicate: NSPredicate? = nil
        ) {
            self.title = title
            self.predicate = predicate
        }
    }
    
    #if os(macOS)
    @Published var actived: Tag? = .dashboard
    @Published var configuration: Configuration = .init()
    #else
    @Published var selection: Nomination? = nil
    #endif
    
    #if os(macOS)
    func open(_ panel: Tag, with configuration: Configuration?) {
        if let solidConfiguration = configuration {
            self.configuration = solidConfiguration
        }
        actived = panel
    }
    #endif
}
