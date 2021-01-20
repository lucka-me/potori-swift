//
//  MainSidebar.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI

struct SidebarNavigation: View {
    
    @EnvironmentObject var service: Service
    @State private var isDashboardActive = true

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: dashboard, isActive: $isDashboardActive) {
                    Label("view.dashboard", systemImage: "gauge")
                }
                
                #if os(iOS)
                Section(header: Text("view.misc")) {
                    NavigationLink(destination: PreferencesView()) {
                        Label("view.preferences", systemImage: "gearshape")
                    }
                }
                #endif
            }
            .frame(minWidth: 150)
            .listStyle(SidebarListStyle())
            .toolbar {
                ToolbarItemGroup {
                    #if os(macOS)
                    Button(action: toggleSidebar) {
                        Label("Toggle Sidebar", systemImage: "sidebar.left")
                    }
                    #endif
                }
            }
        }
    }
    
    @ViewBuilder
    private var dashboard: some View {
        #if os(macOS)
        NavigationView {
            DashboardView()
                .frame(minWidth: 350)
        }
        #else
        DashboardView()
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
