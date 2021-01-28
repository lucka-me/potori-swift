//
//  NominationContextMenu.swift
//  Potori
//
//  Created by Lucka on 25/1/2021.
//

import SwiftUI

struct NominationContextMenu: View {
    
    @Environment(\.openURL) private var openURL

    let nomination: Nomination
    
    var body: some View {
        Button(action: {
            openURL(nomination.brainstormingURL)
        }) {
            Label("view.nominations.menuBrainstorming", systemImage: "bolt")
        }
        if nomination.hasLngLat {
            Button(action: {
                openURL(nomination.intelURL)
            }) {
                Label("view.nominations.menuIntel", systemImage: "map")
            }
        }
    }
}

#if DEBUG
struct NominationContextMenu_Previews: PreviewProvider {    
    static var previews: some View {
        NominationContextMenu(nomination: Dia.preview.nominations[0])
    }
}
#endif
