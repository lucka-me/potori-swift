//
//  ListNavigator.swift
//  Potori
//
//  Created by Lucka on 10/7/2021.
//

import SwiftUI

class ListNavigator: ObservableObject {
    
    struct Configuration {
        let title: LocalizedStringKey
        let predicate: NSPredicate?
        let selection: String?
        
        init(
            _ title: LocalizedStringKey = "view.dashboard.highlights.all",
            predicate: NSPredicate? = nil,
            selection: String? = nil
        ) {
            self.title = title
            self.predicate = predicate
            self.selection = selection
        }
    }
    
    var title: LocalizedStringKey = "view.dashboard.highlights.all"
    var predicate: NSPredicate? = nil
    @Published var selection: String? = nil
    
    
    var configuration: Configuration {
        set {
            title = newValue.title
            predicate = newValue.predicate
            selection = newValue.selection
        }
        get {
            .init(title, predicate: predicate, selection: selection)
        }
    }
}
