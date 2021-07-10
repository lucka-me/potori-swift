//
//  MainMap.swift
//  Potori
//
//  Created by Lucka on 2/1/2021.
//

import SwiftUI
import MapKit

struct NominationMap: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    private let configuration: ListNavigator.Configuration
    private let fetchRequest: FetchRequest<Nomination>
    private var nominations: [ Nomination ] {
        fetchRequest.wrappedValue.filter { $0.hasLngLat }
    }
    
    init(_ configuration: ListNavigator.Configuration) {
        self.configuration = configuration
        fetchRequest = .init(
            entity: Nomination.entity(),
            sortDescriptors: Nomination.sortDescriptorsByDate,
            predicate: configuration.predicate
        )
    }
    
    var body: some View {
        #if os(macOS)
        FusionMap(nominations)
            .navigationTitle(config.title)
        #else
        FusionMap(nominations)
            .navigationTitle("view.map")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.container, edges: .horizontal)
        #endif
    }
}

#if DEBUG
struct MainMap_Previews: PreviewProvider {
    static let dia = Dia.preview
    static var previews: some View {
        NominationMap(.init("view.map"))
            .environment(\.managedObjectContext, dia.viewContext)
    }
}
#endif
