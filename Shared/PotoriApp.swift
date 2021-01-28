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
    
    private let dia = Dia.shared
    private let service = Service.shared
    
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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    service.scheduleRefresh()
                }
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
                    #if os(macOS)
                    Preferences.register()
                    #endif
                    if Preferences.General.refreshOnOpen {
                        service.refresh()
                    }
                    URLCache.shared.diskCapacity = 100 * 1024 * 1024
                }
            }
    }
}
