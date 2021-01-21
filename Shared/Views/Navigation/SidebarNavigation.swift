//
//  MainSidebar.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI
import Combine

struct SidebarNavigation: View {

    @StateObject private var model: NavigationModel = .init()

    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: dashboard,
                    tag: NavigationModel.View.dashboard,
                    selection: $model.activeView
                ) {
                    NavigationModel.ViewLabel.dashboard
                }
                #if os(macOS)
                NavigationLink(
                    destination: NominationList(model.list).frame(minWidth: 500),
                    tag: NavigationModel.View.list,
                    selection: $model.activeView
                ) {
                    NavigationModel.ViewLabel.list
                }
                #else
                Section(header: Text("view.misc")) {
                    NavigationLink(
                        destination: PreferencesView(),
                        tag: NavigationModel.View.preference,
                        selection: $model.activeView
                    ) {
                        NavigationModel.ViewLabel.preferences
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
        DashboardView(listConfig: $model.list)
            .frame(minWidth: 500)
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
