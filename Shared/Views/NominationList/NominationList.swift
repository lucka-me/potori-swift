//
//  NominationList.swift
//  Potori
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

struct NominationList: View {
    
    struct Configuration {
        let title: LocalizedStringKey
        let predicate: NSPredicate?
        let selection: String?
        #if os(macOS)
        let open: Bool
        #endif
        
        
        init(_ title: LocalizedStringKey, _ predicate: NSPredicate? = nil, _ selection: String? = nil, open: Bool = true) {
            self.title = title
            self.predicate = predicate
            self.selection = selection
            #if os(macOS)
            self.open = open
            #endif
        }
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var service: Service
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @State private var selection: String?
    
    private let config: Configuration
    private let fetchRequest: FetchRequest<Nomination>
    private var nominations: FetchedResults<Nomination> {
        fetchRequest.wrappedValue
    }
    
    init(_ configuration: Configuration) {
        config = configuration

        fetchRequest = .init(
            entity: Nomination.entity(),
            sortDescriptors: Nomination.sortDescriptorsByDate,
            predicate: config.predicate
        )
    }
    
    var body: some View {
        #if os(macOS)
        NavigationView {
            list
                .listStyle(PlainListStyle())
                .frame(minWidth: 250)
        }
        #else
        list.listStyle(InsetGroupedListStyle())
        #endif
        
    }
    
    @ViewBuilder
    private var list: some View {
        List {
            ForEach(nominations) { nomination in
                NavigationLink(
                    destination: NominationDetails(nomination: nomination),
                    tag: nomination.id,
                    selection: $selection
                ) {
                    NominationListRow(nomination: nomination)
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
                    if index < nominations.endIndex {
                        viewContext.delete(nominations[index])
                    }
                }
                service.save()
            }
            .deleteDisabled(service.status != .idle)
        }
        .navigationTitle(config.title)
        .onAppear {
            selection = config.selection
        }
    }
}

#if DEBUG
struct NominationList_Previews: PreviewProvider {

    static let service = Service.preview

    static var previews: some View {
        NominationList(.init("view.dashboard.highlight.nominations"))
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
