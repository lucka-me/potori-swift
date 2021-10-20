//
//  ContentView.swift
//  macOS
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var dia: Dia
    @ObservedObject private var panelNavigator = PanelNavigator()
    
    @State private var nomination: Nomination? = nil

    var body: some View {
        SidebarNavigation()
            .frame(minHeight: 300)
            .environmentObject(alert)
            .environmentObject(panelNavigator)
            .sheet(item: $nomination) { item in
                VStack(alignment: .leading) {
                    HStack {
                        Text(nomination.title)
                            .font(.largeTitle)
                        Spacer()
                    }
                    .padding([ .top, .horizontal ])
                    
                    NominationDetails(nomination: nomination)
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
                .frame(minHeight: 300)
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
