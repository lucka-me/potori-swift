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
    @State private var rect: MKMapRect = .world

    private let config: Navigation.OpenNominationsConfiguration
    private let fetchRequest: FetchRequest<Nomination>
    private var nominations: [Nomination] {
        fetchRequest.wrappedValue.filter { $0.hasLngLat }
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
        Map(mapRect: $rect, annotationItems: nominations) { nomination in
            MapPin(
                coordinate: nomination.location,
                tint: nomination.statusData.color
            )
        }
        .navigationTitle(config.title)
        .onAppear(perform: prepareRect)
        .ignoresSafeArea()
    }
    
    private func prepareRect() {
        // X -> lng, Y -> lat
        var minLng = 181.0
        var maxLng = -181.0
        var minLat = 91.0
        var maxLat = -91.0
        for nomination in nominations {
            minLng = min(minLng, nomination.longitude)
            maxLng = max(maxLng, nomination.longitude)
            minLat = min(minLat, nomination.latitude)
            maxLat = max(maxLat, nomination.latitude)
        }
        if (minLng < 181) {
            let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: maxLat, longitude: minLng))
            let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: minLat, longitude: maxLng))
            rect = MKMapRect(
                x: topLeft.x,
                y: topLeft.y,
                width: bottomRight.x - topLeft.x,
                height: bottomRight.y - topLeft.y
            )
        }
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
