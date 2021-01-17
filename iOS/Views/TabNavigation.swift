//
//  MainTabView.swift
//  Potori (iOS)
//
//  Created by Lucka on 1/1/2021.
//

import SwiftUI

struct TabNavigation: View {
    
    @State private var isPresentedFilterSheet = false
    
    var body: some View {
        TabView {
            nominationList
                .tabItem { Label("view.nominations", systemImage: "list.bullet") }
            StatsView()
                .tabItem { Label("view.stats", systemImage: "chart.bar")}
            MainMap()
                .tabItem { Label("view.map", systemImage: "map") }
            PreferencesView()
                .tabItem { Label("view.preferences", systemImage: "gearshape") }
        }
    }
    
    @ViewBuilder
    private var nominationList: some View {
        NavigationView {
            NominationList()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            self.isPresentedFilterSheet.toggle()
                        } label: {
                            Label("Filter", systemImage: "line.horizontal.3.decrease.circle")
                        }
                    }
                }
                .sheet(isPresented: $isPresentedFilterSheet) {
                    NavigationView {
                        List { FilterView() }
                            .listStyle(InsetGroupedListStyle())
                            .navigationTitle("view.filter")
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button { } label: {
                                        Label("view.filter.dismiss", systemImage: "xmark")
                                    }
                                }
                            }
                    }
                }
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
