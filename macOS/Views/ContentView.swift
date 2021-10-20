//
//  ContentView.swift
//  macOS
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject private var panelNavigator = PanelNavigator()
    
    @State private var nomination: Nomination? = nil

    var body: some View {
        SidebarNavigation()
            .frame(minHeight: 300)
            .environmentObject(panelNavigator)
            
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
