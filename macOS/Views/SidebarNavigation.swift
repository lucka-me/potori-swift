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
                    tag: Navigation.Panel.dashboard,
                    selection: $navigation.activePanel
                ) {
                    DashboardView().frame(minWidth: 350)
                } label: {
                    Navigation.PanelLabel.dashboard
                }
                NavigationLink(
                    tag: Navigation.Panel.list,
                    selection: $navigation.activePanel
                ) {
                    NominationList(navigation.listConfig).frame(minWidth: 250)
                } label: {
                    Navigation.PanelLabel.list
                }
                NavigationLink(
                    tag: Navigation.Panel.map,
                    selection: $navigation.activePanel
                ) {
                    NominationMap(navigation.listConfig).frame(minWidth: 350)
                } label: {
                    Navigation.PanelLabel.map
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
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
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
