//
//  MainSidebar.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI
import Combine

struct SidebarNavigation: View {

    @EnvironmentObject private var navigation: Navigation

    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: dashboard,
                    tag: Navigation.Panel.dashboard,
                    selection: $navigation.activePanel
                ) {
                    Navigation.PanelLabel.dashboard
                }
                #if os(macOS)
                NavigationLink(
                    destination: NominationList(navigation.listConfig),
                    tag: Navigation.Panel.list,
                    selection: $navigation.activePanel
                ) {
                    Navigation.PanelLabel.list
                }
                NavigationLink(
                    destination: NominationMap(navigation.listConfig).frame(minWidth: 350),
                    tag: Navigation.Panel.map,
                    selection: $navigation.activePanel
                ) {
                    Navigation.PanelLabel.map
                }
                #else
                Section(header: Text("view.misc")) {
                    NavigationLink(
                        destination: PreferencesView(),
                        tag: Navigation.Panel.preference,
                        selection: $navigation.activePanel
                    ) {
                        Navigation.PanelLabel.preferences
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
                        Label("view.toggleSidebar", systemImage: "sidebar.left")
                    }
                    #endif
                }
            }
            #if os(iOS)
            dashboard
            #endif
        }
    }
    
    @ViewBuilder
    private var dashboard: some View {
        #if os(macOS)
        DashboardView()
            .frame(minWidth: 350)
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

    static let navigation: Navigation = .init()

    static var previews: some View {
        SidebarNavigation()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environmentObject(navigation)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
