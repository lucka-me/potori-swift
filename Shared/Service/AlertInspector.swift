//
//  AlertInspector.swift
//  Potori
//
//  Created by Lucka on 25/5/2021.
//

import SwiftUI

class AlertInspector: ObservableObject {
    @Published var isPresented = false
    var alert = Alert(title: .init(""))
    
    func push(title: LocalizedStringKey, message: LocalizedStringKey? = nil) {
        DispatchQueue.main.async {
            var messageText: Text? = nil
            if let solidMessage = message {
                messageText = .init(solidMessage)
            }
            self.alert = .init(title: .init(title), message: messageText)
            self.isPresented = true
        }
    }
}
