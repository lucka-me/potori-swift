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
                .navigationTitle("Nominations")
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Nomination")
                }
            PreferenceView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Preference")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigation()
            .environmentObject(Service())
    }
}
