//
//  MainTabView.swift
//  Potori (iOS)
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI

struct TabNavigation: View {
    
    @StateObject private var model: NavigationModel = .init()
    
    var body: some View {
        TabView(selection: $model.activeView) {
            NavigationView { DashboardView() }
                .tabItem { NavigationModel.ViewLabel.dashboard }
                .tag(NavigationModel.View.dashboard as NavigationModel.View?)
            NavigationView { PreferencesView() }
                .tabItem { NavigationModel.ViewLabel.preferences }
                .tag(NavigationModel.View.preference as NavigationModel.View?)
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
