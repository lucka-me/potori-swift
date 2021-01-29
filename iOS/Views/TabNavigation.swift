//
//  MainTabView.swift
//  Potori (iOS)
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI

struct TabNavigation: View {
    
    @EnvironmentObject private var navigation: Navigation
    
    var body: some View {
        TabView(selection: $navigation.activePanel) {
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
    
    static let navigation: Navigation = .init()

    static var previews: some View {
        TabNavigation()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environmentObject(navigation)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
