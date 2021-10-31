//
//  PotoriApp.swift
//  Shared
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

@main
struct PotoriApp: App {
    
    #if os(macOS)
    private static let majorMatchURLs: Set<String> = [
        GoogleKit.Auth.redirectURL
    ]
    private static let detailsMatchURLs: Set<String> = [ "potori://details" ]
    #else
    private static let majorMatchURLs: Set<String> = [
        "potori://details",
        GoogleKit.Auth.redirectURL
    ]
    #endif
    
    private let dia = Dia.shared
    private let service = Service.shared

    @State private var firstAppear = true

    var body: some Scene {
        WindowGroup {
            SceneCommon()
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
            /// Prevent opening new window when opend by URL
            /// - SeeAlso [Stack Overflow](https://stackoverflow.com/a/66664474/10276204)
                .handlesExternalEvents(preferring: Self.majorMatchURLs, allowing: Self.majorMatchURLs)
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
            
            #if os(macOS)
            PotoriCommands()
            #endif
        }
        .handlesExternalEvents(matching: Self.majorMatchURLs)
        
        #if os(macOS)
        WindowGroup("view.details") {
            DetailsSceneView()
                .environmentObject(dia)
        }
        .handlesExternalEvents(matching: Self.detailsMatchURLs)
        #endif
    }
}
