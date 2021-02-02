//
//  NominationList.swift
//  Potori
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

struct NominationList: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var dia: Dia
    @EnvironmentObject private var service: Service
    
    @State private var selection: String?
    
    private let config: Navigation.OpenNominationsConfiguration
    private let fetchRequest: FetchRequest<Nomination>
    private var nominations: FetchedResults<Nomination> {
        fetchRequest.wrappedValue
    }
    
    init(_ configuration: Navigation.OpenNominationsConfiguration) {
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
                .contextMenu { NominationContextMenu(nomination: nomination) }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    if index < nominations.endIndex {
                        viewContext.delete(nominations[index])
                    }
                }
                dia.save()
            }
            .deleteDisabled(service.status != .idle)
        }
        .navigationTitle(config.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                OpenNominationMapLink(config, plain: false) {
                    Label("view.map", systemImage: "map")
                }
            }
        }
        .onAppear {
            selection = config.selection
        }
    }
}

#if DEBUG
struct NominationList_Previews: PreviewProvider {
    static var previews: some View {
        NominationList(.init("view.dashboard.highlight.all"))
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
