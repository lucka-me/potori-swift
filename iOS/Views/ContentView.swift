//
//  ContentView.swift
//  iOS
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct ContentView: View {
    
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
        .sheet(isPresented: $presentingPreferenceSheet) {
            SheetView {
                PreferencesView()
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
