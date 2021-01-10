//
//  NominationDetailsMap.swift
//  Potori
//
//  Created by Lucka on 30/12/2020.
//

import SwiftUI
import MapKit

struct IdentifiableMarker: Identifiable {
    let id = UUID()
    var location: CLLocationCoordinate2D
}

struct NominationDetailsMap: View {
    
    var location: CLLocationCoordinate2D
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    private let markers: [IdentifiableMarker]
    
    init(location: CLLocationCoordinate2D) {
        self.location = location
        markers = [IdentifiableMarker(location: location)]
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: markers) { marker in
            MapPin(coordinate: marker.location)
        }
            .onAppear {
                DispatchQueue.main.async {
                    setupMap()
                }
            }
    }
    
    private func setupMap() {
        region = MKCoordinateRegion(
            center: location,
            latitudinalMeters: 200, longitudinalMeters: 200
        )
    }
}

#if DEBUG
struct NominationDetailsMap_Previews: PreviewProvider {
    static var previews: some View {
        NominationDetailsMap(
            location: CLLocationCoordinate2D(
                latitude: Nomination.defaultLatitude,
                longitude: Nomination.defaultLongitude
            )
        )
    }
}
#endif
