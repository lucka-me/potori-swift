//
//  ContentView.swift
//  Potori
//
//  Created by Lucka on 29/12/2020.
//

import SwiftUI

struct ContentView: View {
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @EnvironmentObject private var service: Service

    var body: some View {
        if let solidPack = service.match.pack {
            let matchView = MatchView(pack: solidPack)
            navigation
                .sheet(isPresented: .constant(true)) {
                    if !matchView.confirmed {
                        service.match.match(solidPack, nil)
                    }
                } content: {
                    matchView
                }
        } else {
            navigation
        }
    }
    
    @ViewBuilder
    private var navigation: some View {
        #if os(macOS)
        SidebarNavigation()
        #else
        if horizontalSizeClass == .compact {
            TabNavigation()
        } else {
            SidebarNavigation()
        }
        #endif
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
