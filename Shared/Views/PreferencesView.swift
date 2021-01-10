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
            group(AccountGroup())
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
    
    private func group<Content>(_ content: Content) -> some View where Content : PreferenceGroup {
        #if os(macOS)
        return Group { Form(content: { content }) }
            .tabItem { Label(content.title, systemImage: content.icon) }
        #else
        return Section(header: Text(content.title)) { content }
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

fileprivate struct AccountGroup: View, PreferenceGroup {
    
    let title: LocalizedStringKey = "view.preferences.account"
    let icon: String = "person.crop.circle"
    
    @AppStorage(Preferences.Account.keyGoogleSync) var prefGoogleSync = false
    
    @EnvironmentObject var service: Service
    #if os(iOS)
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var isPresentingActionSheetAccountGoogle = false
    #endif
    
    var body: some View {
        #if os(macOS)
        HStack(alignment: .firstTextBaseline) {
            Text("view.preferences.account.google")
                .font(.headline)
            Text(service.auth.login ? service.auth.mail : "view.preferences.account.notLinked")
                .lineLimit(1)
        }
        Button(
            service.auth.login ? "view.preferences.account.unlink" : "view.preferences.account.link",
            action: service.auth.login ? logOut : logIn
        )
        #else
        HStack {
            Text("view.preferences.account.google")
            Spacer()
            Text(service.auth.login ? "view.preferences.account.linked" : "view.preferences.account.notLinked")
                .foregroundColor(service.auth.login ? .green : .red)
        }
        .onTapGesture {
            self.isPresentingActionSheetAccountGoogle = true
        }
        .actionSheet(isPresented: $isPresentingActionSheetAccountGoogle) {
            ActionSheet(
                title: service.auth.login ? Text(service.auth.mail) : Text("view.preferences.account.googleAccount"),
                buttons: [
                    service.auth.login
                        ? .destructive(Text("view.preferences.account.unlink")) { service.auth.logOut() }
                        : .default(Text("view.preferences.account.link"), action: logIn),
                    .cancel()
                ]
            )
        }
        #endif
        if service.auth.login {
            Toggle("view.preferences.account.googleSync", isOn: $prefGoogleSync)
            Button("view.preferences.account.googleSyncNow") {
                service.sync()
            }
            .disabled(service.status != .idle)
            Button("view.preferences.account.googleUploadNow") {
                service.sync(performDownload: false)
            }
            .disabled(service.status != .idle)
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
    
    private var buttons: some View {
        Group {
            Button("view.preferences.data.importNominations") {
                isPresentingImporter = true
            }
            Button("view.preferences.data.exportNominations") {
                isPresentingExporter = true
            }
        }
    }
}

fileprivate struct AboutGroup: View, PreferenceGroup {
    
    let title: LocalizedStringKey = "view.preferences.about"
    let icon: String = "info.circle"
    
    var body: some View {
        Link("view.preferences.about.repo", destination: URL(string: "https://github.com/lucka-me/potori-swift")!)
        if
            let infoDict = Bundle.main.infoDictionary,
            let version = infoDict["CFBundleShortVersionString"] as? String,
            let build = infoDict["CFBundleVersion"] as? String {
            HStack {
                Text("view.preferences.about.version")
                #if os(iOS)
                Spacer()
                #endif
                Text("\(version)-d\(StatusKit.shared.version) (\(build))")
            }
        }
    }
}
