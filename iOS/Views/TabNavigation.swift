//
//  MainTabView.swift
//  Potori (iOS)
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI

struct TabNavigation: View {
    var body: some View {
        TabView {
            NavigationView {
                DashboardView()
                    .navigationTitle("view.dashboard")
            }
            .tabItem { Label("view.dashboard", systemImage: "gauge")}
            PreferencesView()
                .tabItem { Label("view.preferences", systemImage: "gearshape") }
        }
    }
}

#if DEBUG
struct TabNavigation_Previews: PreviewProvider {
    static let service = Service.preview
    static let filter = FilterManager()
    static var previews: some View {
        TabNavigation()
            .environmentObject(service)
            .environmentObject(filter)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
