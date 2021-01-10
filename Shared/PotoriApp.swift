//
//  PotoriApp.swift
//  Shared
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

@main
struct PotoriApp: App {
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    private var service = Service.shared
    
    @State private var firstAppear = true

    var body: some Scene {
        let mainWindow = WindowGroup {
            ContentView()
                .environmentObject(service)
                .environment(\.managedObjectContext, service.containerContext)
                .onAppear {
                    if firstAppear && Preferences.General.refreshOnOpen {
                        firstAppear = false
                        service.refresh()
                    }
                }
        }
        
        #if os(macOS)
        mainWindow
            .commands {
                PotoriCommands()
            }
        Settings {
            PreferencesView()
                .environmentObject(service)
        }
        #else
        mainWindow
        #endif
    }
}
