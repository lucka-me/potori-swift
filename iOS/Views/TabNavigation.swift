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
            NominationList()
                .tabItem { Label("view.nominations", systemImage: "list.bullet") }
            StatsView()
                .tabItem { Label("view.stats", systemImage: "chart.bar")}
            MainMap()
                .tabItem { Label("view.map", systemImage: "map") }
            PreferencesView()
                .tabItem { Label("view.preferences", systemImage: "gearshape") }
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
