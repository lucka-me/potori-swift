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
    @EnvironmentObject private var navigation: Navigation
    @EnvironmentObject private var service: Service

    var body: some View {
        navigationView
            .sheet(isPresented: $navigation.showMatchView) {
                EmptyView()
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
            .environmentObject(navigation)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
