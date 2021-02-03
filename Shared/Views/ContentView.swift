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
    @EnvironmentObject private var navigation: Navigation
    #endif
    @EnvironmentObject private var service: Service

    var body: some View {
        if let solidPack = service.match.pack {
            showMatchSheet(pack: solidPack)
        } else {
            navigationView
        }
    }
    
    @ViewBuilder
    private var navigationView: some View {
        #if os(macOS)
        SidebarNavigation()
            .frame(minHeight: 300)
        #else
        if horizontalSizeClass == .compact {
            TabNavigation()
        } else {
            SidebarNavigation()
        }
        #endif
    }
    
    @ViewBuilder
    private func showMatchSheet(pack: MatchKit.Pack) -> some View {
        let matchView = MatchView(pack: pack)
        navigationView
            .sheet(isPresented: .constant(true)) {
                if !matchView.confirmed {
                    service.match.match(pack, nil)
                }
            } content: { matchView }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    
    static let navigation: Navigation = .init()
    
    static var previews: some View {
        ContentView()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environmentObject(navigation)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
