//
//  MainSidebar.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI
import Combine

struct SidebarNavigation: View {

    @EnvironmentObject private var navigator: Navigator

    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    tag: Navigator.Tag.dashboard,
                    selection: $panelNavigator.actived
                ) {
                    DashboardView()
                        .frame(minWidth: 350)
                } label: {
                    Label.dashboard
                }
                NavigationLink(
                    tag: Navigator.Tag.list,
                    selection: $panelNavigator.actived
                ) {
                    NominationList(navigator.configuration)
                        .frame(minWidth: 250)
                } label: {
                    Label.list
                }
                NavigationLink(
                    tag: Navigator.Tag.map,
                    selection: $panelNavigator.actived
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
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

#if DEBUG
struct SidebarNavigation_Previews: PreviewProvider {

    static let listNavigation = ListNavigator()
    static let panelNavigation = PanelNavigator()

    static var previews: some View {
        SidebarNavigation()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environmentObject(listNavigation)
            .environmentObject(panelNavigation)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
