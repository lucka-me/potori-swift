//
//  MainMap.swift
//  Potori
//
//  Created by Lucka on 2/1/2021.
//

import SwiftUI
import MapKit

struct MainMap: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Nomination.entity(), sortDescriptors: [])
    
    private var nominations: FetchedResults<Nomination>
    
    @State private var rect: MKMapRect = MKMapRect.world
    
    var body: some View {
        Map(mapRect: $rect, annotationItems: filteredNominations) { nomination in
            MapPin(
                coordinate: nomination.location,
                tint: nomination.statusData.color
            )
        }
        .onAppear {
            // X -> lng, Y -> lat
            var minLng = 181.0
            var maxLng = -181.0
            var minLat = 91.0
            var maxLat = -91.0
            for nomination in nominations {
                if !nomination.hasLngLat {
                    continue
                }
                minLng = min(minLng, nomination.longitude)
                maxLng = max(maxLng, nomination.longitude)
                minLat = min(minLat, nomination.latitude)
                maxLat = max(maxLat, nomination.latitude)
            }
            if (minLng < 181) {
                let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: maxLat, longitude: minLng))
                let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: minLat, longitude: maxLng))
                DispatchQueue.main.async {
                    rect = MKMapRect(
                        x: topLeft.x,
                        y: topLeft.y,
                        width: bottomRight.x - topLeft.x,
                        height: bottomRight.y - topLeft.y)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var filteredNominations: [Nomination] {
        nominations.filter { $0.hasLngLat }
    }
}

#if DEBUG
struct MainMap_Previews: PreviewProvider {
    static let service = Service.preview
    static var previews: some View {
        MainMap()
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
