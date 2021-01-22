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
        TabView(selection: $model.activeView) {
            NavigationView { DashboardView() }
                .tabItem { Navigation.ViewLabel.dashboard }
                .tag(Navigation.View.dashboard as Navigation.View?)
            NavigationView { PreferencesView() }
                .tabItem { Navigation.ViewLabel.preferences }
                .tag(Navigation.View.preference as Navigation.View?)
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
