//
//  ContentView.swift
//  iOS
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var dia: Dia
    @EnvironmentObject private var navigator: Navigator

    var body: some View {
        NavigationView {
            DashboardView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink {
                            PreferencesView()
                        } label: {
                            Label.preferences
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
        .sheet(item: $navigator.selection) { nomination in
            SheetView(nomination.title) {
                NominationDetails(nomination: nomination)
            }
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
                navigator.selection = dia.firstNomination(matches: .init(format: "id == %@", id))
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
