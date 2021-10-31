//
//  AlertInspector.swift
//  Potori
//
//  Created by Lucka on 25/5/2021.
//

import SwiftUI

class AlertInspector: ObservableObject {
    @Published var isPresented = false
    var titleKey: LocalizedStringKey = ""
    var message: LocalizedStringKey = ""
    
    @MainActor
    func push(_ titleKey: LocalizedStringKey, message: LocalizedStringKey? = nil) {
        self.titleKey = titleKey
        self.message = message ?? ""
        self.isPresented = true
    }
}
