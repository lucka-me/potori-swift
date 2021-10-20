//
//  PotoriApp.swift
//  Shared
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

@main
struct PotoriApp: App {
    
    /// Prevent opening new window when opend by URL
    /// - SeeAlso [Stack Overflow](https://stackoverflow.com/a/66664474/10276204)
    private static let matchURLs: Set<String> = [
        "potori://details",
        GoogleKit.Auth.redirectURL
    ]
    
    private let dia = Dia.shared
    private let service = Service.shared

    @State private var firstAppear = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dia)
                .environmentObject(service)
                .environment(\.managedObjectContext, dia.viewContext)
                .task {
                    guard firstAppear else { return }
                    firstAppear = false
                    URLCache.shared.diskCapacity = 100 * 1024 * 1024
                    if UserDefaults.General.refreshOnOpen {
                        let _ = try? await service.refresh()
                    }
                }
                .handlesExternalEvents(preferring: Self.matchURLs, allowing: [ "*" ])
                .onOpenURL { url in
                    #if os(macOS)
                    if url.scheme != "potori" {
                        GoogleKit.Auth.shared.onOpenURL(url)
                    }
                    #endif
                }
        }
        .commands {
            SidebarCommands()
        }
        .handlesExternalEvents(matching: Self.matchURLs)
        #if os(macOS)
        Settings {
            PreferencesView()
                .environmentObject(dia)
                .environmentObject(service)
        }
        #endif
    }
}
