//
//  NominationList.swift
//  Potori
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

struct NominationList: View {
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var appDelegate: AppDelegate
    #endif
    
    @EnvironmentObject private var service: Service
    @EnvironmentObject private var filter: FilterManager
    
    var body: some View {
        content
            .navigationTitle("view.nominations")
            .toolbar {
                ToolbarItem(placement: refreshPlacement) {
                    Button(action: {
                        service.refresh()
                    }) {
                        Label("view.nominations.refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(service.status != .idle)
                }
                ToolbarItem(placement: .principal) {
                    switch service.status {
                    case .processingMails:
                        ProgressView(value: service.progress, total: 1.0)
                            .frame(idealWidth: progressIdealWidth)
                    default:
                        Text(LocalizedStringKey(service.status.rawValue))
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            }
    }
    
    private var refreshPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .navigation
        #else
        if horizontalSizeClass == .compact {
            return .navigation
        }
        return .primaryAction
        #endif
    }
    
    private var progressIdealWidth: CGFloat {
        #if os(macOS)
        return 150
        #else
        return 100
        #endif
    }
    
    @ViewBuilder
    private var content: some View {
        if service.status == .idle && service.isNominationsEmpty {
            emptyPrompt
        } else {
            #if os(macOS)
            List { ListContent(filter.predicate) }
                .listStyle(PlainListStyle())
                .frame(minWidth: 250)
            #else
            List { ListContent(filter.predicate) }
                .listStyle(InsetGroupedListStyle())
            #endif
        }
    }
    
    private var emptyPrompt: some View {
        VStack {
            if service.auth.login {
                Text("view.nominations.refreshPrompt")
            } else {
                Text("view.nominations.linkPrompt")
                Button("view.preferences.google.link") {
                    #if os(macOS)
                    service.auth.logIn()
                    #else
                    service.auth.logIn(appDelegate: appDelegate)
                    #endif
                }
            }
        }
        .padding()
    }
}

#if DEBUG
struct NominationList_Previews: PreviewProvider {

    static let service = Service.preview
    static let filter = FilterManager()

    static var previews: some View {
        NominationList()
            .environmentObject(service)
            .environmentObject(filter)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif

fileprivate struct ListContent: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var service: Service
    @EnvironmentObject private var filter: FilterManager
    
    private let fetchRequest: FetchRequest<Nomination>
    private var nominations: FetchedResults<Nomination> {
        fetchRequest.wrappedValue
    }
    
    @State private var firstAppear = true
    @State private var selected: String? = nil
    
    init(_ predicate: NSPredicate) {
        fetchRequest = .init(
            entity: Nomination.entity(),
            sortDescriptors: [ NSSortDescriptor(keyPath: \Nomination.title, ascending: true) ],
            predicate: predicate
        )
    }
    
    var body: some View {
        let filtered = filter.filterByReason(Array(nominations))
        ForEach(filtered) { nomination in
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
        .onDelete { indexSet in
            for index in indexSet {
                if index < filtered.endIndex {
                    viewContext.delete(filtered[index])
                }
            }
            service.save()
        }
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
}
