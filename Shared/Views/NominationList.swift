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
    
    private let config: Navigation.ListConfiguration
    private let fetchRequest: FetchRequest<Nomination>
    private var nominations: FetchedResults<Nomination> {
        fetchRequest.wrappedValue
    }
    
    init(_ configuration: Navigation.ListConfiguration) {
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
                        dia.delete(nominations[index])
                    }
                }
                dia.save()
            }
            .deleteDisabled(service.status != .idle)
        }
        .navigationTitle(config.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NominationMapLink(config) {
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
        NominationList(.init("view.dashboard.highlights.all"))
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif

fileprivate struct NominationListRow: View {
    
    var nomination: Nomination
    
    var body: some View {
        let content = HStack(alignment: .center) {
            RemoteImage(nomination.imageURL)
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            VStack(alignment: .leading) {
                HStack {
                    Text(nomination.title)
                        .font(.title2)
                        .lineLimit(1)
                }
                Text(
                    DateFormatter.localizedString(
                        from: nomination.statusCode == .pending ?
                            nomination.confirmedTime : nomination.resultTime,
                        dateStyle: .medium, timeStyle: .none
                    )
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }.frame(height: 50, alignment: .top)
            
            Spacer()
            
            Image(systemName: nomination.statusData.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(nomination.statusData.color)
        }
        
        #if os(macOS)
        content
        #else
        content.padding(.vertical, 5)
        #endif
    }
}
