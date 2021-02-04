//
//  Preferences.swift
//  Potori
//
//  Created by Lucka on 5/1/2021.
//

import SwiftUI

struct PreferencesView : View {
    
    var body: some View {
        
        let groups = Group {
            group { GeneralGroup()  }
            group { GoogleGroup()   }
            group { DataGroup()     }
            group { AboutGroup()    }
        }
        
        #if os(macOS)
        TabView { groups }
            .frame(minWidth: 400, minHeight: 300)
            .padding()
        #else
        Form { groups }
            .navigationTitle("view.preferences")
            .listStyle(InsetGroupedListStyle())
        #endif
    }
    
    @ViewBuilder
    private func group<Group: PreferenceGroup>(_ group: () -> Group) -> some View {
        let content = group()
        #if os(macOS)
        Form(content: { content })
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
            .environmentObject(Service.shared)
    }
}
#endif

protocol PreferenceGroup: View {
    var title: LocalizedStringKey { get }
    var icon: String { get }
}

fileprivate struct GeneralGroup: View, PreferenceGroup {
    let title: LocalizedStringKey = "view.preferences.general"
    let icon: String = "gearshape"
    
    @AppStorage(Preferences.General.keyRefreshOnOpen) var prefRefreshOnOpen = false
    #if os(iOS)
    @AppStorage(Preferences.General.keyBackgroundRefresh) var prefBackgroundRefresh = false
    #endif
    @AppStorage(Preferences.General.keyQueryAfterLatest) var prefQueryAfterLatest = true
    
    var body: some View {
        Toggle("view.preferences.general.refreshOnOpen", isOn: $prefRefreshOnOpen)
        #if os(iOS)
        Toggle("view.preferences.general.backgroundRefresh", isOn: $prefBackgroundRefresh)
        #endif
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
    
    @AppStorage(Preferences.Google.keySync) var prefSync = false
    
    @EnvironmentObject var service: Service
    #if os(iOS)
    @State private var isPresentedActionSheetAccount = false
    #endif
    @State private var migrateAlert: MigrateAlert? = nil
    @State private var migrateCount: Int = 0
    
    var body: some View {
        #if os(macOS)
        HStack(alignment: .firstTextBaseline) {
            Text("view.preferences.google.account")
                .font(.headline)
            service.google.auth.login ? Text(service.google.auth.mail) : Text("view.preferences.google.notLinked")
        }
        .lineLimit(1)
        Button(
            service.google.auth.login ? "view.preferences.google.unlink" : "view.preferences.google.link",
            action: service.google.auth.login ? logOut : logIn
        )
        #else
        HStack {
            Text("view.preferences.google.account")
            Spacer()
            Text(service.google.auth.login ? "view.preferences.google.linked" : "view.preferences.google.notLinked")
                .foregroundColor(service.google.auth.login ? .green : .red)
        }
        .onTapGesture {
            isPresentedActionSheetAccount.toggle()
        }
        .actionSheet(isPresented: $isPresentedActionSheetAccount) {
            ActionSheet(
                title: service.google.auth.login ? Text(service.google.auth.mail) : Text("view.preferences.google.account"),
                buttons: [
                    service.google.auth.login
                        ? .destructive(Text("view.preferences.google.unlink"), action: logOut)
                        : .default(Text("view.preferences.google.link"), action: logIn),
                    .cancel()
                ]
            )
        }
        #endif
        if service.google.auth.login {
            Toggle("view.preferences.google.sync", isOn: $prefSync)

            Button("view.preferences.google.syncNow") {
                service.sync()
            }
            .disabled(service.status != .idle)

            Button("view.preferences.google.uploadNow") {
                service.sync(performDownload: false)
            }
            .disabled(service.status != .idle)
            
            Button("view.preferences.google.migrate") {
                migrateAlert = .confirm
            }
            .disabled(service.status != .idle)
            .alert(item: $migrateAlert) { type in
                if type == .confirm {
                    return Alert(
                        title: Text("view.preferences.google.migrate"),
                        message: Text("view.preferences.google.migrate.alert"),
                        primaryButton: Alert.Button.destructive(Text("view.preferences.google.migrate.alert.confirm")) {
                            service.migrateFromGoogleDrive { count in
                                migrateCount = count
                                self.migrateAlert = .finish
                            }
                        },
                        secondaryButton: Alert.Button.cancel()
                    )
                } else {
                    return Alert(
                        title: Text("view.preferences.google.migrate"),
                        message: Text("view.preferences.google.migrate.finished \(migrateCount)")
                    )
                }
            }
        }
    }
    
    private func logIn() {
        service.google.auth.logIn()
    }
    
    private func logOut() {
        service.google.auth.logOut()
    }
}

fileprivate struct DataGroup: View, PreferenceGroup {
    
    let title: LocalizedStringKey = "view.preferences.data"
    let icon: String = "tray.2"
    
    @EnvironmentObject var dia: Dia
    @EnvironmentObject var service: Service

    #if os(macOS)
    @State private var isPresentingExporter = false
    @State private var isPresentingImporter = false
    #endif
    @State private var isPresentingAlertClearAll = false
    
    var body: some View {
        #if os(macOS)
        ImportExportView()
        #else
        NavigationLink(destination: ImportExportView())  { Text("view.preferences.data.importExport") }
        #endif
        Button("view.preferences.data.clearNominations") {
            isPresentingAlertClearAll = true
        }
        .disabled(service.status != .idle)
        .alert(isPresented: $isPresentingAlertClearAll) {
            Alert(
                title: Text("view.preferences.data.clearNominations"),
                message: Text("view.preferences.data.clearNominations.alert"),
                primaryButton: Alert.Button.destructive(Text("view.preferences.data.clearNominations.clear")) {
                    dia.clear()
                    dia.save()
                },
                secondaryButton: Alert.Button.cancel()
            )
        }
    }
}


/// Import / Export part of Preferences / Data
///
/// - macOS: Buttons,
/// - iOS: List that should be passed to `NavigationLink`, since the sheets could not be attached to list items
fileprivate struct ImportExportView: View {
    
    private enum ResultAlert: Identifiable {
        case importer
        case exporter
        
        var id: Int { self.hashValue }
    }

    @EnvironmentObject var service: Service
    
    @State private var isPresentedExporter = false
    @State private var isPresentedImporter = false
    @State private var resultAlert: ResultAlert? = nil
    @State private var resultMessage: LocalizedStringKey = ""
    
    var body: some View {
        content
            .fileImporter(
                isPresented: $isPresentedImporter,
                allowedContentTypes: NominationJSONDocument.readableContentTypes
            ) { result in
                print("Imported")
                do {
                    let url = try result.get()
                    let count = try service.importNominations(url: url)
                    resultMessage = "view.preferences.data.importNominations.success \(count)"
                } catch {
                    resultMessage = "view.preferences.data.importNominations.failure \(error.localizedDescription)"
                }
                resultAlert = .importer
            }
            .fileExporter(
                isPresented: $isPresentedExporter,
                document: service.exportNominations(),
                contentType: .json,
                defaultFilename: "nominations.json"
            ) { result in
                print("Exported")
                do {
                    let _ = try result.get()
                    resultMessage = "view.preferences.data.exportNominations.success"
                } catch {
                    resultMessage = "view.preferences.data.exportNominations.failure \(error.localizedDescription)"
                }
                resultAlert = .exporter
            }
            .alert(item: $resultAlert) { type in
                let title: LocalizedStringKey
                switch type {
                    case .importer: title = "view.preferences.data.importNominations"
                    case .exporter: title = "view.preferences.data.exportNominations"
                }
                return Alert(title: Text(title), message: Text(resultMessage))
            }
    }
    
    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        buttons
        #else
        List { buttons }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("view.preferences.data.importExport")
        #endif
    }
    
    @ViewBuilder
    private var buttons: some View {
        Button("view.preferences.data.importNominations") {
            isPresentedImporter = true
        }
        Button("view.preferences.data.exportNominations") {
            isPresentedExporter = true
        }
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
