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

    var body: some View {
        #if os(macOS)
        SidebarNavigation()
        #else
        //TabNavigation()
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
    static let service = Service.preview
    static var previews: some View {
        ContentView()
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
