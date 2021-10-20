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
    @ObservedObject private var listNavigator = ListNavigator()
    
    @SceneStorage(.scenePresentingMatchSheet) private var presentingMatchSheet = false
    
    var body: some View {
        ContentView()
            .environmentObject(alert)
            .environmentObject(listNavigator)
            .alert(isPresented: $alert.isPresented) {
                alert.alert
            }
            .sheet(isPresented: $presentingMatchSheet) {
                MatchView()
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
