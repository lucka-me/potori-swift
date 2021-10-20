//
//  Label.swift
//  Potori
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

extension Label where Title == Text, Icon == Image {
    static var preferences: Label {
        Label("view.preferences", systemImage: "gear")
    }
    
    static var dismiss: Label {
        Label("action.dismiss", systemImage: "xmark")
    }
}
