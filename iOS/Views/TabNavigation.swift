//
//  MainTabView.swift
//  Potori (iOS)
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI

struct TabNavigation: View {
    
    @StateObject private var model: Navigation = .init()
    
    var body: some View {
        TabView(selection: $model.activePanel) {
            NavigationView { DashboardView() }
                .tabItem { Navigation.PanelLabel.dashboard }
                .tag(Navigation.Panel.dashboard as Navigation.Panel?)
            NavigationView { PreferencesView() }
                .tabItem { Navigation.PanelLabel.preferences }
                .tag(Navigation.Panel.preference as Navigation.Panel?)
        }
    }
}

#if DEBUG
struct TabNavigation_Previews: PreviewProvider {

    static var previews: some View {
        TabNavigation()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
