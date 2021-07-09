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
    @FetchRequest(
        entity: Nomination.entity(),
        sortDescriptors: Nomination.sortDescriptorsByDate,
        animation: .default
    ) private var nominations: FetchedResults<Nomination>
    @State private var selection: String?
    
    private let configuration: Navigation.ListConfiguration
    
    init(_ configuration: Navigation.ListConfiguration) {
        self.configuration = configuration
    }
    
    var body: some View {
        List {
            ForEach(nominations) { nomination in
                NavigationLink(
                    tag: nomination.id,
                    selection: $selection
                ) {
                    NominationDetails(nomination: nomination)
                } label: {
                    NominationListRow(nomination)
                }
                .contextMenu { NominationContextMenu(nomination: nomination) }
            }
            .onDelete { indexSet in
                let sorted = indexSet.sorted(by: >)
                for index in sorted {
                    if index < nominations.endIndex {
                        dia.delete(nominations[index])
                    }
                }
                dia.save()
            }
            .deleteDisabled(service.status != .idle)
        }
        .listStyle(style)
        .navigationTitle(configuration.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NominationMapLink(configuration) {
                    Label("view.map", systemImage: "map")
                }
            }
        }
        .onAppear {
            nominations.nsPredicate = configuration.predicate
            selection = configuration.selection
        }
    }
    
    private var style: some ListStyle {
        #if os(macOS)
        .bordered
        #else
        .insetGrouped
        #endif
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
    
    private let nomination: Nomination
    
    init (_ nomination: Nomination) {
        self.nomination = nomination
    }
    
    var body: some View {
        HStack(alignment: .center) {
            AsyncImage(url: nomination.imageURL)
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
            }
            .frame(height: 50, alignment: .top)
            
            Spacer()
            
            Image(systemName: nomination.statusData.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(nomination.statusData.color)
        }
    }
}
