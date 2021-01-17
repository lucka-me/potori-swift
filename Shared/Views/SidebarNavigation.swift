//
//  MainSidebar.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI

struct SidebarNavigation: View {
    
    @EnvironmentObject var service: Service
    @State private var isNominationListActive = true

    var body: some View {
        NavigationView {
            List {
                panelsSection
                
                #if os(iOS)
                Section(header: Text("view.misc")) {
                    NavigationLink(destination: PreferencesView()) { Label("view.preferences", systemImage: "gearshape") }
                }
                #endif
            }
            .frame(minWidth: 150)
            .listStyle(SidebarListStyle())
            .toolbar {
                ToolbarItemGroup {
                    #if os(macOS)
                    Button(action: toggleSidebar) { Label("Toggle Sidebar", systemImage: "sidebar.left") }
                    #endif
                }
            }
        }
    }
    
    private var panelsSection: some View {
        Section(header: Text("view.panels")) {
            NavigationLink(
                destination: nominationList,
                isActive: $isNominationListActive
            ) { Label("view.nominations", systemImage: "list.bullet") }
            NavigationLink(destination: StatsView()) { Label("view.stats", systemImage: "chart.bar") }
            NavigationLink(destination: MainMap()) { Label("view.map", systemImage: "map") }
        }
    }
    
    @ViewBuilder
    private var nominationList: some View {
        #if os(macOS)
        NavigationView { NominationList() }
        #else
        NominationList()
        #endif
    }
    
    #if os(macOS)
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    #endif
}

#if DEBUG
struct SidebarNavigation_Previews: PreviewProvider {

    static let service = Service.preview
    static var previews: some View {
        SidebarNavigation()
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
