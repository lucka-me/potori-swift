//
//  Preferences.swift
//  Potori
//
//  Created by Lucka on 5/1/2021.
//

import SwiftUI

struct PreferencesView : View {
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    var body: some View {
        
        let groups = Group {
            group(GeneralGroup())
            group(GoogleGroup())
            group(DataGroup())
            group(AboutGroup())
        }
        
        #if os(macOS)
        TabView { groups }
            .frame(minWidth: 400, minHeight: 300)
            .padding()
        #else
        let list = Form { groups }
            .navigationTitle("view.preferences")
            .listStyle(InsetGroupedListStyle())
        if horizontalSizeClass == .compact {
            NavigationView { list }
        } else {
            list
        }
        #endif
    }
    
    @ViewBuilder
    private func group<Content>(_ content: Content) -> some View where Content : PreferenceGroup {
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
            .environmentObject(Service.preview)
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
    
    var body: some View {
        Toggle("view.preferences.general.refreshOnOpen", isOn: $prefRefreshOnOpen)
    }
}

fileprivate struct GoogleGroup: View, PreferenceGroup {
    
    let title: LocalizedStringKey = "view.preferences.google"
    let icon: String = "person.crop.circle"
    
    @AppStorage(Preferences.Google.keySync) var prefSync = false
    
    @EnvironmentObject var service: Service
    #if os(iOS)
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var isPresentingActionSheetAccount = false
    #endif
    @State private var isPresentingAlertMigrate = false
    
    var body: some View {
        #if os(macOS)
        HStack(alignment: .firstTextBaseline) {
            Text("view.preferences.google.account")
                .font(.headline)
            service.auth.login ? Text(service.auth.mail) : Text("view.preferences.google.notLinked")
        }
        .lineLimit(1)
        Button(
            service.auth.login ? "view.preferences.google.unlink" : "view.preferences.google.link",
            action: service.auth.login ? logOut : logIn
        )
        #else
        HStack {
            Text("view.preferences.google.account")
            Spacer()
            Text(service.auth.login ? "view.preferences.google.linked" : "view.preferences.google.notLinked")
                .foregroundColor(service.auth.login ? .green : .red)
        }
        .onTapGesture {
            self.isPresentingActionSheetAccount = true
        }
        .actionSheet(isPresented: $isPresentingActionSheetAccount) {
            ActionSheet(
                title: service.auth.login ? Text(service.auth.mail) : Text("view.preferences.google.account"),
                buttons: [
                    service.auth.login
                        ? .destructive(Text("view.preferences.google.unlink")) { service.auth.logOut() }
                        : .default(Text("view.preferences.google.link"), action: logIn),
                    .cancel()
                ]
            )
        }
        #endif
        if service.auth.login {
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
                self.isPresentingAlertMigrate = true
            }
            .disabled(service.status != .idle)
            .alert(isPresented: $isPresentingAlertMigrate) {
                Alert(
                    title: Text("view.preferences.google.migrate"),
                    message: Text("view.preferences.google.migrate.alert"),
                    primaryButton: Alert.Button.destructive(Text("view.preferences.google.migrate.alert.confirm")) {
                        service.migrateFromGoogleDrive()
                    },
                    secondaryButton: Alert.Button.cancel()
                )
            }
        }
    }
    
    private func logIn() {
        #if os(macOS)
        service.auth.logIn()
        #else
        service.auth.logIn(appDelegate: appDelegate)
        #endif
    }
    
    private func logOut() {
        service.auth.logOut()
    }
}

fileprivate struct DataGroup: View, PreferenceGroup {
    
    let title: LocalizedStringKey = "view.preferences.data"
    let icon: String = "tray.2"
    
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
                    service.clear()
                    service.save()
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

    @EnvironmentObject var service: Service
    
    @State private var isPresentingExporter = false
    @State private var isPresentingImporter = false
    
    var body: some View {
        
        #if os(macOS)
        let contents = buttons
        #else
        let contents = List { buttons }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("view.preferences.data.importExport")
        #endif
        
        contents
            .fileImporter(
                isPresented: $isPresentingImporter,
                allowedContentTypes: NominationJSONDocument.readableContentTypes,
                onCompletion: service.importNominations
            )
            .fileExporter(
                isPresented: $isPresentingExporter,
                document: service.exportNominations(),
                contentType: .json,
                defaultFilename: "nominations.json",
                onCompletion: { _ in }
            )
    }
    
    @ViewBuilder
    private var buttons: some View {
        Button("view.preferences.data.importNominations") {
            isPresentingImporter = true
        }
        Button("view.preferences.data.exportNominations") {
            isPresentingExporter = true
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
                Text("\(version)-d\(Umi.shared.version) (\(build))")
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
    }
}
