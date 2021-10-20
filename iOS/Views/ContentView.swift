//
//  ContentView.swift
//  iOS
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var dia: Dia
    @ObservedObject private var alert = AlertInspector()
    @ObservedObject private var listNavigator = ListNavigator()
    @ObservedObject private var panelNavigator = PanelNavigator()
    
    @State private var nomination: Nomination? = nil
    @State private var presentingPreferenceSheet = false

    var body: some View {
        NavigationView {
            DashboardView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            presentingPreferenceSheet.toggle()
                        } label: {
                            Label.preferences
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
        .environmentObject(alert)
        .environmentObject(panelNavigator)
        .environmentObject(listNavigator)
        .sheet(isPresented: $presentingPreferenceSheet) {
            NavigationView {
                PreferencesView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                presentingPreferenceSheet.toggle()
                            } label: {
                                Label.dismiss
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $panelNavigator.showMatchView) {
            MatchView()
        }
        .sheet(item: $nomination) { item in
            NavigationView {
                NominationDetails(nomination: item)
                    .environmentObject(alert)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                self.nomination = nil
                            } label: {
                                Label.dismiss
                            }
                        }
                    }
            }
            .navigationViewStyle(.stack)
        }
        .alert(isPresented: $alert.isPresented) {
            alert.alert
        }
        .onOpenURL { url in
            guard
                url.scheme == "potori",
                let host = url.host
            else {
                return
            }
            if host == "details" {
                let id = url.lastPathComponent
                nomination = dia.firstNomination(matches: .init(format: "id == %@", id))
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
