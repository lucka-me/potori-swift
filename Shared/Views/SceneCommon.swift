//
//  SceneCommon.swift
//  Potori
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct SceneCommon: View {
    
    @EnvironmentObject private var dia: Dia
    @ObservedObject private var alert = AlertInspector()
    @ObservedObject private var navigator = Navigator()
    
    @SceneStorage(.scenePresentingMatchSheet) private var presentingMatchSheet = false
    @State private var nomination: Nomination? = nil
    
    var body: some View {
        ContentView()
            .environmentObject(alert)
            .environmentObject(navigator)
            .alert(isPresented: $alert.isPresented) {
                alert.alert
            }
            .sheet(isPresented: $presentingMatchSheet) {
                SheetView("view.match", minWidth: 300, minHeight: 350, defaultDismiss: false) {
                    MatchView()
                }
            }
            .sheet(item: $nomination) { item in
                SheetView(item.title) {
                    NominationDetails(nomination: item)
                        .environmentObject(alert)
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
                    nomination = dia.firstNomination(matches: .init(format: "id == %@", id))
                }
            }
    }
}

#if DEBUG
struct SceneCommon_Previews: PreviewProvider {
    static var previews: some View {
        SceneCommon()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
