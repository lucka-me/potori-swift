//
//  Preferences.swift
//  Potori
//
//  Created by Lucka on 5/1/2021.
//

import SwiftUI

struct PreferencesView : View {
    
    #if os(macOS)
    @ObservedObject private var alert = AlertInspector()
    #endif
    
    var body: some View {
        #if os(macOS)
        TabView { groups }
            .frame(minWidth: 400, minHeight: 300)
            .padding()
            .alert(isPresented: $alert.isPresented) {
                alert.alert
            }
        #else
        Form { groups }
            .navigationTitle("view.preferences")
            .listStyle(InsetGroupedListStyle())
        #endif
    }
    
    @ViewBuilder
    private var groups: some View {
        group { GeneralGroup()  }
        group { GoogleGroup()   }
        group { BrainstormingGroup()    }
        group { DataGroup()     }
        group { AboutGroup()    }
    }
    
    @ViewBuilder
    private func group<Group: PreferenceGroup>(_ group: () -> Group) -> some View {
        let content = group()
        #if os(macOS)
        Form(content: { content })
            .environmentObject(alert)
            .tabItem { Label(content.title, systemImage: content.icon) }
        #else
        Section(header: Text(content.title)) { content }
        #endif
    }
}

#if DEBUG
struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(Dia.preview)
            .environmentObject(Service.preview)
    }
}
#endif

fileprivate protocol PreferenceGroup: View {
    var title: LocalizedStringKey { get }
    var icon: String { get }
}

fileprivate struct GeneralGroup: View, PreferenceGroup {
    let title: LocalizedStringKey = "view.preferences.general"
    let icon: String = "gearshape"
    
    @AppStorage(UserDefaults.General.keyRefreshOnOpen, store: .shared) var prefRefreshOnOpen = false
    @AppStorage(UserDefaults.General.keyBackgroundRefresh, store: .shared) var prefBackgroundRefresh = false
    @AppStorage(UserDefaults.General.keyQueryAfterLatest, store: .shared) var prefQueryAfterLatest = true
    
    var body: some View {
        Toggle("view.preferences.general.refreshOnOpen", isOn: $prefRefreshOnOpen)
        Toggle("view.preferences.general.backgroundRefresh", isOn: $prefBackgroundRefresh)
        Toggle("view.preferences.general.queryAfterLatest", isOn: $prefQueryAfterLatest)
    }
}

fileprivate struct GoogleGroup: View, PreferenceGroup {
    
    private enum MigrateAlert: Identifiable {
        case confirm
        case finish
        
        var id: Int { self.hashValue }
    }
    
    let title: LocalizedStringKey = "view.preferences.google"
    let icon: String = "person.crop.circle"
    
    @AppStorage(UserDefaults.Google.keySync, store: .shared) var prefSync = false
    
    @EnvironmentObject private var alert: AlertInspector
    @EnvironmentObject private var service: Service
    @ObservedObject private var auth = GoogleKit.Auth.shared
    @State private var isPresentedConfirmMigrate = false
    #if os(iOS)
    @State private var isPresentedActionSheetAccount = false
    #endif
    
    var body: some View {
        #if os(macOS)
        HStack(alignment: .firstTextBaseline) {
            Text("view.preferences.google.account")
                .font(.headline)
            auth.authorized ? Text(auth.mail) : Text("view.preferences.google.notLinked")
        }
        .lineLimit(1)
        Button(
            auth.authorized ? "view.preferences.google.unlink" : "view.preferences.google.link",
            action: auth.authorized ? auth.unlink : auth.link
        )
        #else
        Button {
            isPresentedActionSheetAccount.toggle()
        } label: {
            HStack {
                Text("view.preferences.google.account")
                Spacer()
                Text(auth.authorized ? "view.preferences.google.linked" : "view.preferences.google.notLinked")
                    .foregroundColor(auth.authorized ? .green : .red)
            }
        }
        .actionSheet(isPresented: $isPresentedActionSheetAccount) {
            ActionSheet(
                title: auth.authorized ? Text(auth.mail) : Text("view.preferences.google.account"),
                buttons: [
                    auth.authorized
                        ? .destructive(Text("view.preferences.google.unlink"), action: auth.unlink)
                        : .default(Text("view.preferences.google.link"), action: auth.link),
                    .cancel()
                ]
            )
        }
        #endif
        if auth.authorized {
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
                isPresentedConfirmMigrate.toggle()
            }
            .disabled(service.status != .idle)
            .confirmationDialog(
                "view.preferences.google.migrate",
                isPresented: $isPresentedConfirmMigrate
            ) {
                Button("view.preferences.google.migrate.alert.confirm", action: migrate)
            } message: {
                Text("view.preferences.google.migrate.alert")
            }
        }
    }
    
    private func migrate() {
        Task {
            do {
                let count = try await service.migrateFromGoogleDrive()
                alert.push(
                    title: "view.preferences.google.migrate",
                    message: "view.preferences.google.migrate.finished \(count)"
                )
            } catch {
                // TODO: Alert
            }
        }
    }
}

fileprivate struct BrainstormingGroup: View, PreferenceGroup {
    let title = LocalizedStringKey("view.preferences.brainstorming")
    let icon = "hand.point.right"
    
    @AppStorage(UserDefaults.Brainstorming.keyQuery, store: .shared) var prefQuery = false
    
    var body: some View {
        Toggle("view.preferences.brainstorming.query", isOn: $prefQuery)
    }
}

fileprivate struct DataGroup: View, PreferenceGroup {
    
    let title: LocalizedStringKey = "view.preferences.data"
    let icon: String = "tray.2"
    
    @EnvironmentObject private var alert: AlertInspector
    @EnvironmentObject private var dia: Dia
    @EnvironmentObject private var service: Service
    
    @State private var isPresentedConfirmClear = false
    
    var body: some View {
        #if os(macOS)
        ImportExportView()
        #else
        NavigationLink(destination: ImportExportView())  { Text("view.preferences.data.importExport") }
        #endif
        Button("view.preferences.data.clearNominations") {
            isPresentedConfirmClear.toggle()
        }
        .disabled(service.status != .idle)
        .confirmationDialog(
            "view.preferences.data.clearNominations",
            isPresented: $isPresentedConfirmClear
        ) {
            Button("view.preferences.data.clearNominations.clear", role: .destructive) {
                dia.clear()
                dia.save()
            }
        } message: {
            Text("view.preferences.data.clearNominations.alert")
        }
    }
}


/// Import / Export part of Preferences / Data
///
/// - macOS: Buttons,
/// - iOS: List that should be passed to `NavigationLink`, since the sheets could not be attached to list items
fileprivate struct ImportExportView: View {
    
    private static let stringImport: LocalizedStringKey = "view.preferences.data.import"
    private static let stringExport: LocalizedStringKey = "view.preferences.data.export"

    @EnvironmentObject private var alert: AlertInspector
    @EnvironmentObject private var dia: Dia
    
    @State private var isPresentedExporter = false
    @State private var isPresentedImporter = false
    
    var body: some View {
        content
            .fileImporter(
                isPresented: $isPresentedImporter,
                allowedContentTypes: NominationJSON.Document.readableContentTypes
            ) { result in
                let message: LocalizedStringKey
                do {
                    let url = try result.get()
                    let data = try Data(contentsOf: url)
                    let count = try dia.importNominations(data)
                    message = "view.preferences.data.nominations.import.success \(count)"
                } catch {
                    message = "view.preferences.data.nominations.failure \(error.localizedDescription)"
                }
                alert.push(title: Self.stringImport, message: message)
            }
            .fileExporter(
                isPresented: $isPresentedExporter,
                document: dia.exportNominations(),
                contentType: .json,
                defaultFilename: "nominations.json"
            ) { result in
                let message: LocalizedStringKey
                do {
                    let _ = try result.get()
                    message = "view.preferences.data.nominations.export.success"
                } catch {
                    message = "view.preferences.data.nominations.failure \(error.localizedDescription)"
                }
                alert.push(title: Self.stringExport, message: message)
            }
    }
    
    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        sections
        #else
        List { sections }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("view.preferences.data.importExport")
        #endif
    }
    
    @ViewBuilder
    private var sections: some View {
        Section(header: Text("view.preferences.data.nominations")) {
            Button("view.preferences.data.import") {
                isPresentedImporter = true
            }
            Button("view.preferences.data.export") {
                isPresentedExporter = true
            }
        }
        Section(header: Text("view.preferences.data.wayfarer")) {
            Button("view.preferences.data.import", action: importWayfarer)
            Link("view.preferences.data.wayfarer.link", destination: URL(string: "https://wayfarer.nianticlabs.com/api/v1/vault/manage")!)
        }
    }
    
    private func importWayfarer() {
        #if os(macOS)
        let json = NSPasteboard.general.string(forType: .string)
        #else
        let json = UIPasteboard.general.string
        #endif
        guard let data = json?.data(using: .utf8) else {
            alert.push(
                title: Self.stringImport,
                message: "view.preferences.data.wayfarer.import.empty"
            )
            return
        }
        let message: LocalizedStringKey
        do {
            let count = try dia.importWayfarer(data)
            message = "view.preferences.data.wayfarer.import.success \(count)"
        } catch {
            message = .init(error.localizedDescription)
        }
        alert.push(
            title: Self.stringImport,
            message: message
        )
    }
}

fileprivate struct AboutGroup: View, PreferenceGroup {
    
    let title: LocalizedStringKey = "view.preferences.about"
    let icon: String = "info.circle"
    
    var body: some View {
        if
            let infoDict = Bundle.main.infoDictionary,
            let version = infoDict["CFBundleShortVersionString"] as? String,
            let build = infoDict["CFBundleVersion"] as? String {
            HStack {
                Text("view.preferences.about.appVersion")
                #if os(iOS)
                Spacer()
                #endif
                Text("\(version) (\(build))")
            }
        }
        HStack {
            Text("view.preferences.about.dataVersion")
            #if os(iOS)
            Spacer()
            #endif
            Text(Umi.shared.version)
        }
        Link("view.preferences.about.repo", destination: URL(string: "https://github.com/lucka-me/potori-swift")!)
        Link("view.preferences.about.privacy", destination: URL(string: "https://potori.lucka.moe/docs/privacy/")!)
        Link("view.preferences.about.telegram", destination: URL(string: "https://t.me/potori")!)
    }
}
