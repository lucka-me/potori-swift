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

    private let configuration: Navigator.Configuration
    private let fetchRequest: FetchRequest<Nomination>
    private var nominations: [ Nomination ] {
        fetchRequest.wrappedValue.filter { $0.hasLngLat }
    }
    
    init(_ configuration: Navigator.Configuration) {
        self.configuration = configuration
        fetchRequest = .init(
            entity: Nomination.entity(),
            sortDescriptors: Nomination.sortDescriptorsByDate,
            predicate: configuration.predicate
        )
    }
    
    var body: some View {
        #if os(macOS)
        FusionMap(nominations.compactMap { $0.annotation })
            .navigationTitle(configuration.title)
        #else
        FusionMap(nominations.compactMap { $0.annotation })
            .navigationTitle("view.map")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.container, edges: .horizontal)
            .ignoresSafeArea(.container, edges: .bottom)
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
