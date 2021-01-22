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

    static let service = Service.preview

    static var previews: some View {
        TabNavigation()
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
