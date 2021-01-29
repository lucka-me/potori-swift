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
            #if os(iOS)
            if
                let id = navigation.openNominations.selection,
                let nomination = Dia.shared.nomination(by: id) {
                showNominationDetails(nomination: nomination)
            } else {
                navigationView
            }
            #else
            navigationView
            #endif
        }
    }
    
    @ViewBuilder
    private var navigationView: some View {
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
    
    #if os(iOS)
    @ViewBuilder
    private func showNominationDetails(nomination: Nomination) -> some View {
        navigationView
            .sheet(isPresented: .constant(true)) {
                navigation.openNominations = .init("")
            } content: {
                NavigationView {
                    NominationDetails(nomination: nomination)
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Button {
                                    navigation.openNominations = .init("")
                                } label: {
                                    Label("Dismiss", systemImage: "xmark")
                                }
                            }
                        }
                }
            }
    }
    #endif
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
