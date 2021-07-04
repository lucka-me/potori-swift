//
//  ContentView.swift
//  Potori
//
//  Created by Lucka on 29/12/2020.
//

import SwiftUI

struct ContentView: View {
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @EnvironmentObject private var dia: Dia
    @ObservedObject private var alert = AlertInspector()
    @ObservedObject private var navigation = Navigation()
    @State private var nomination: Nomination? = nil

    var body: some View {
        navigationView
            .environmentObject(alert)
            .environmentObject(navigation)
            .sheet(isPresented: $navigation.showMatchView) {
                MatchView()
            }
            .sheet(item: $nomination) { item in
                #if os(macOS)
                detailsSheet(of: item)
                    .frame(minHeight: 300)
                #else
                NavigationView {
                    detailsSheet(of: item)
                }
                #endif
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
    
    @ViewBuilder
    private var navigationView: some View {
        #if os(macOS)
        SidebarNavigation()
            .frame(minHeight: 300)
        #else
        if horizontalSizeClass == .compact {
            TabNavigation()
        } else {
            SidebarNavigation()
        }
        #endif
    }
    
    @ViewBuilder
    private func detailsSheet(of nomination: Nomination) -> some View {
        #if os(macOS)
        HStack {
            Text(nomination.title)
                .font(.largeTitle)
            Spacer()
        }
        .padding([ .top, .horizontal ])
        #endif
        NominationDetails(nomination: nomination)
            .environmentObject(alert)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        self.nomination = nil
                    } label: {
                        Label("action.dismiss", systemImage: "xmark")
                    }
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
