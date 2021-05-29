//
//  PotoriApp.swift
//  Shared
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

@main
struct PotoriApp: App {
    
    private let dia = Dia.shared
    private let service = Service.shared

    @State private var firstAppear = true

    var body: some Scene {
        WindowGroup { content }
            .commands {
                SidebarCommands()
            }
        #if os(macOS)
        Settings {
            PreferencesView()
                .environmentObject(dia)
                .environmentObject(service)
        }
        #endif
    }
    
    @ViewBuilder
    private var content: some View {
        ContentView()
            .environmentObject(dia)
            .environmentObject(service)
            .environment(\.managedObjectContext, dia.viewContext)
            .onAppear {
                if firstAppear {
                    firstAppear = false
                    if UserDefaults.General.refreshOnOpen {
                        service.refresh()
                    }
                    URLCache.shared.diskCapacity = 100 * 1024 * 1024
                }
            }
            .onOpenURL { url in
                #if os(macOS)
                if url.scheme != "potori" {
                    GoogleKit.Auth.shared.onOpenURL(url)
                }
                #endif
            }
    }
}
