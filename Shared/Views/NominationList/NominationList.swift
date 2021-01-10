//
//  NominationList.swift
//  Potori
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

struct NominationList: View {
    
    @EnvironmentObject var service: Service
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openURL) private var openURL
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var appDelegate: AppDelegate
    #endif
    
    @State private var firstAppear = true
    @State private var selected: String? = nil

    @FetchRequest(entity: Nomination.entity(), sortDescriptors: [
        NSSortDescriptor(keyPath: \Nomination.title, ascending: true)
    ])
    
    private var nominations: FetchedResults<Nomination>
    
    var body: some View {
        #if os(macOS)
        NavigationView {
            content
        }
        #else
        if horizontalSizeClass == .compact {
            NavigationView {
                content
            }
        } else {
            content
        }
        #endif
    }
    
    private var content: some View {
        Group {
            if nominations.isEmpty && service.status == .idle {
                emptyPrompt
            } else {
                #if os(macOS)
                list
                    .listStyle(PlainListStyle())
                    .frame(minWidth: 250)
                #else
                list.listStyle(InsetGroupedListStyle())
                #endif
            }
        }
    }
    
    private var list: some View {
        List { listContent }
            .navigationTitle("view.nominations")
            .toolbar {
                #if os(macOS)
                let refreshPlacement: ToolbarItemPlacement = .navigation
                #else
                let refreshPlacement: ToolbarItemPlacement = .primaryAction
                #endif
                ToolbarItem(placement: refreshPlacement) {
                    #if os(macOS)
                    refreshButton
                    #else
                    if service.status == .processingMails {
                        ProgressView(value: service.progress, total: 1.0)
                            .frame(idealWidth: 100)
                    } else {
                        refreshButton
                    }
                    #endif
                }
                #if os(macOS)
                ToolbarItem(placement: .principal) {
                    if service.status == .processingMails {
                        ProgressView(value: service.progress, total: 1.0)
                            .frame(idealWidth: 150)
                    }
                }
                #endif
            }
    }
    
    private var listContent: some View {
        ForEach(nominations) { nomination in
            NavigationLink(
                destination: NominationDetails(nomination: nomination),
                tag: nomination.id,
                selection: $selected
            ) {
                NominationItem(nomination: nomination)
            }
            .contextMenu {
                Button(action: {
                    openURL.callAsFunction(nomination.brainstormingURL)
                }) {
                    Label("view.nominations.menuBrainstorming", systemImage: "bolt")
                }
                if nomination.hasLngLat {
                    Button(action: {
                        openURL.callAsFunction(nomination.intelURL)
                    }) {
                        Label("view.nominations.menuIntel", systemImage: "map")
                    }
                }
            }
        }
        .onDelete(perform: delete)
        .deleteDisabled(service.status != .idle)
        .onAppear {
            #if os(macOS)
            if firstAppear && selected == nil {
                firstAppear = false
                selected = nominations.first?.id
            }
            #endif
        }
    }
    
    private var refreshButton: some View {
        Group {
            Button(action: {
                service.refresh()
            }) {
                Label("view.nominations.refresh", systemImage: "arrow.clockwise")
            }
            .disabled(service.status != .idle)
        }
    }
    
    private var emptyPrompt: some View {
        VStack {
            if service.auth.login {
                refreshButton
            } else {
                Text("view.nominations.linkPrompt")
                Button("view.preferences.account.link") {
                    #if os(macOS)
                    service.auth.logIn()
                    #else
                    service.auth.logIn(appDelegate: appDelegate)
                    #endif
                }
            }
        }
        .navigationTitle("view.nominations")
        .padding()
    }
    
    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            if index < nominations.endIndex {
                viewContext.delete(nominations[index])
            }
        }
        service.save()
    }
}

#if DEBUG
struct NominationList_Previews: PreviewProvider {
    static let service = Service.preview
    static var previews: some View {
        NominationList()
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
