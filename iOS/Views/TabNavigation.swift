//
//  MainTabView.swift
//  Potori (iOS)
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI

struct TabNavigation: View {
    
    @EnvironmentObject private var navigator: PanelNavigator
    
    var body: some View {
        TabView(selection: $navigator.actived) {
            NavigationView { DashboardView() }
                .tabItem { PanelNavigator.LabelView.dashboard }
                .tag(PanelNavigator.Tag.dashboard)
            NavigationView { PreferencesView() }
                .tabItem { PanelNavigator.LabelView.preferences }
                .tag(PanelNavigator.Tag.preference)
        }
        .navigationViewStyle(StackNavigationViewStyle.stack)
    }
}

#if DEBUG
struct TabNavigation_Previews: PreviewProvider {
    
    static let navigator = PanelNavigator()

    static var previews: some View {
        TabNavigation()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environmentObject(navigator)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
