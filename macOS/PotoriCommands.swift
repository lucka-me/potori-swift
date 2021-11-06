//
//  PotoriCommands.swift
//  macOS
//
//  Created by Lucka on 31/10/2021.
//

import SwiftUI

struct PotoriCommands: Commands {
    var body: some Commands {
        GeneralCommands()
        GoogleCommands()
        BrainstormingCommands()
        DataCommands()
        AboutCommands()
    }
}

fileprivate struct GeneralCommands: Commands {
    
    @AppStorage(UserDefaults.General.keyRefreshOnOpen, store: .shared) var prefRefreshOnOpen = false
    @AppStorage(UserDefaults.General.keyBackgroundRefresh, store: .shared) var prefBackgroundRefresh = false
    @AppStorage(UserDefaults.General.keyQueryAfterLatest, store: .shared) var prefQueryAfterLatest = true
    
    var body: some Commands {
        CommandMenu("view.preferences.general") {
            Toggle("view.preferences.general.refreshOnOpen", isOn: $prefRefreshOnOpen)
            Toggle("view.preferences.general.backgroundRefresh", isOn: $prefBackgroundRefresh)
            Toggle("view.preferences.general.queryAfterLatest", isOn: $prefQueryAfterLatest)
        }
    }
}

fileprivate struct GoogleCommands: Commands {
    
    @AppStorage(UserDefaults.Google.keySync, store: .shared) var prefSync = false
    @ObservedObject private var auth = GoogleKit.Auth.shared
    @ObservedObject private var service = Service.shared
    
    var body: some Commands {
        CommandMenu("view.preferences.google") {
            if auth.authorized {
                Text(auth.mail)
            } else {
                Text("view.preferences.google.notLinked")
            }
            Button(
                auth.authorized ? "view.preferences.google.unlink" : "view.preferences.google.link",
                action: auth.authorized ? auth.unlink : auth.link
            )
            if auth.authorized {
                Divider()
                syncCommands
            }
        }
    }
    
    @ViewBuilder
    private var syncCommands: some View {
        Toggle("view.preferences.google.sync", isOn: $prefSync)
        Button("view.preferences.google.syncNow") {
            Task {
                try? await service.sync()
            }
        }
        .disabled(service.status != .idle)

        Button("view.preferences.google.uploadNow") {
            Task {
                try? await service.sync(performDownload: false)
            }
        }
        .disabled(service.status != .idle)
        
        Button("view.preferences.google.migrate") {
            showConfirmationDialog(
                title: .init(localized: "view.preferences.google.migrate"),
                message: .init(localized: "view.preferences.google.migrate.alert"),
                confirmationButtonText: .init(localized: "view.preferences.google.migrate.alert.confirm")
            ) {
                Task {
                    do {
                        let count = try await service.migrateFromGoogleDrive()
                        print("sss \(count)")
                        showAlert(
                            title: .init(localized: "view.preferences.google.migrate"),
                            message: .init(format: .init(localized: "view.preferences.google.migrate.finished"), count)
                        )
                    } catch {
                        // TODO: Alert
                    }
                }
            }
        }
        .disabled(service.status != .idle)
    }
}

fileprivate struct BrainstormingCommands: Commands {
    
    @AppStorage(UserDefaults.Brainstorming.keyQuery, store: .shared) var prefQuery = false
    
    var body: some Commands {
        CommandMenu("view.preferences.brainstorming") {
            Toggle("view.preferences.brainstorming.query", isOn: $prefQuery)
        }
    }
}

fileprivate struct DataCommands: Commands {
    
    @ObservedObject private var dia = Dia.shared
    @State private var isPresentedExporter = false
    @State private var isPresentedImporter = false
    
    var body: some Commands {
        CommandGroup(replacing: .importExport) {
            Menu("view.preferences.data.nominations") {
                Button("view.preferences.data.import") {
                    isPresentedImporter = true
                }
                Button("view.preferences.data.export") {
                    isPresentedExporter = true
                }
                Button("view.preferences.data.clearNominations") {
                    showConfirmationDialog(
                        title: .init(localized: "view.preferences.data.clearNominations"),
                        message: .init(localized: "view.preferences.data.clearNominations.alert"),
                        confirmationButtonText: .init(localized: "view.preferences.data.clearNominations.clear")
                    ) {
                        dia.clear()
                        dia.save()
                    }
                }
            }
            .fileImporter(
                isPresented: $isPresentedImporter,
                allowedContentTypes: NominationJSON.Document.readableContentTypes
            ) { result in
                Task {
                    let message: String
                    do {
                        let url = try result.get()
                        let data = try Data(contentsOf: url)
                        let count = try await dia.importNominations(data)
                        message = .init(format: .init(localized: "view.preferences.data.nominations.import.success"), count)
                    } catch {
                        message = error.localizedDescription
                    }
                    showAlert(title: .init(localized: "view.preferences.data.import"), message: message)
                }
            }
            .fileExporter(
                isPresented: $isPresentedExporter,
                document: dia.exportNominations(),
                contentType: .json,
                defaultFilename: "nominations.json"
            ) { result in
                let message: String
                do {
                    let _ = try result.get()
                    message = .init(localized: "view.preferences.data.nominations.export.success")
                } catch {
                    message = error.localizedDescription
                }
                showAlert(title: .init(localized: "view.preferences.data.export"), message: message)
            }
            
            Menu("view.preferences.data.wayfarer") {
                Button("view.preferences.data.import") {
                    let json = NSPasteboard.general.string(forType: .string)
                    Task {
                        let message: String
                        if let data = json?.data(using: .utf8) {
                            do {
                                let count = try await dia.importWayfarer(data)
                                message = .init(format: .init(localized: "view.preferences.data.wayfarer.import.success"), count)
                            } catch {
                                message = error.localizedDescription
                            }
                        } else {
                            message = .init(localized: "view.preferences.data.wayfarer.import.empty")
                        }
                        showAlert(title: .init(localized: "view.preferences.data.import"), message: message)
                    }
                }
                Link(
                    "view.preferences.data.wayfarer.link",
                    destination: URL(string: "https://wayfarer.nianticlabs.com/api/v1/vault/manage")!
                )
            }
        }
    }
}

fileprivate struct AboutCommands: Commands {
    
    @AppStorage(UserDefaults.Google.keySync, store: .shared) var prefSync = false
    @ObservedObject private var auth = GoogleKit.Auth.shared
    
    var body: some Commands {
        CommandGroup(after: .help) {
            Divider()
            Text("view.preferences.about.dataVersion \(Umi.shared.version)")
            Link("view.preferences.about.repo", destination: URL(string: "https://github.com/lucka-me/potori-swift")!)
            Link("view.preferences.about.privacy", destination: URL(string: "https://potori.lucka.moe/docs/privacy/")!)
            Link("view.preferences.about.telegram", destination: URL(string: "https://t.me/potori")!)
        }
    }
}

fileprivate extension Commands {
    
    typealias ButtonAction = () -> Void
    
    @MainActor
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
    
    @MainActor
    func showConfirmationDialog(
        title: String,
        message: String,
        confirmationButtonText: String,
        confirmationAction: @escaping ButtonAction
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        
        let confirmationButton = alert.addButton(withTitle: confirmationButtonText)
        confirmationButton.tag = NSApplication.ModalResponse.OK.rawValue
        
        alert.addButton(withTitle: .init(localized: "action.cancel"))
        
        switch alert.runModal() {
            case .OK:
                confirmationAction()
            default:
                break
        }
    }
}
