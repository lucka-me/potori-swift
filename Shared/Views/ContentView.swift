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
    @ObservedObject private var navigation = Navigation()

    var body: some View {
        navigationView
            .environmentObject(navigation)
            .sheet(isPresented: $navigation.showMatchView) {
                MatchView()
            }
            .onOpenURL { url in
                if url.scheme == "potori", let host = url.host {
                    if host == "nomination" {
                        let id = url.lastPathComponent
                        navigation.openNominations = .init("view.nominations", nil, id, panel: .list)
                        #if os(iOS)
                        navigation.activePanel = .dashboard
                        navigation.activeLink = Navigation.nominationWidgetTarget
                        #endif
                    }
                }
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
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    
    static let navigation: Navigation = .init()
    
    static var previews: some View {
        ContentView()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
