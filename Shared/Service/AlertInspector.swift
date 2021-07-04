//
//  AlertInspector.swift
//  Potori
//
//  Created by Lucka on 25/5/2021.
//

import SwiftUI

class AlertInspector: ObservableObject {
    @Published var isPresented = false
    var alert = Alert(title: Text(""))
    
    func push(_ alert: Alert) {
        DispatchQueue.main.async {
            self.alert = alert
            self.isPresented = true
        }
    }
}
