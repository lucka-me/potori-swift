//
//  ContentView.swift
//  macOS
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var navigator: Navigator

    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    tag: Navigator.Tag.dashboard,
                    selection: $navigator.actived
                ) {
                    DashboardView()
                        .frame(minWidth: 350)
                } label: {
                    Label.dashboard
                }
                NavigationLink(
                    tag: Navigator.Tag.list,
                    selection: $navigator.actived
                ) {
                    NominationList(navigator.configuration)
                        .frame(minWidth: 250)
                } label: {
                    Label.list
                }
                NavigationLink(
                    tag: Navigator.Tag.map,
                    selection: $navigator.actived
                ) {
                    NominationMap(navigator.configuration)
                        .frame(minWidth: 350)
                } label: {
                    Label.map
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150)
            .toolbar {
                ToolbarItemGroup {
                    Button(action: toggleSidebar) {
                        Label("view.toggleSidebar", systemImage: "sidebar.left")
                    }
                }
            }
            
            Text("Select a panel")
        }
        .frame(minHeight: 300)
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
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
