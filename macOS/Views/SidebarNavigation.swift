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
            }
            .frame(minWidth: 150)
            .listStyle(SidebarListStyle())
            .toolbar {
                ToolbarItemGroup {
                    Button(action: toggleSidebar) {
                        Label("view.toggleSidebar", systemImage: "sidebar.left")
                    }
                }
            }
            dashboard
        }
    }
    
    @ViewBuilder
    private var dashboard: some View {
        DashboardView()
            .frame(minWidth: 350)
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
