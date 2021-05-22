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
    private let navigation: Navigation = .init()

    @State private var firstAppear = true

    var body: some Scene {
        #if os(macOS)
        WindowGroup { content }
            .commands {
                PotoriCommands()
            }
        Settings {
            PreferencesView()
                .environmentObject(dia)
                .environmentObject(service)
        }
        #else
        WindowGroup {
            content
        }
        #endif
    }
    
    @ViewBuilder
    private var content: some View {
        ContentView()
            .environmentObject(dia)
            .environmentObject(service)
            .environmentObject(navigation)
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
                if url.scheme == "potori", let host = url.host {
                    if host == "nomination" {
                        let id = url.lastPathComponent
                        navigation.openNominations = .init("view.nominations", nil, id, panel: .list)
                        #if os(iOS)
                        navigation.activePanel = .dashboard
                        navigation.activeLink = Navigation.nominationWidgetTarget
                        #endif
                    }
                } else {
                    #if os(macOS)
                    GoogleKit.Auth.shared.onOpenURL(url)
                    #endif
                }
            }
    }
}
