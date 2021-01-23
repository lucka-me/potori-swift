//
//  NominationDetailsMap.swift
//  Potori
//
//  Created by Lucka on 30/12/2020.
//

import SwiftUI
import MapKit

struct NominationDetailsMap: View {
    
    let nomination: Nomination
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [ nomination ]) { item in
            MapPin(coordinate: item.location)
        }
            .onAppear {
                DispatchQueue.main.async {
                    setupMap()
                }
            }
    }
    
    private func setupMap() {
        region = MKCoordinateRegion(
            center: nomination.location,
            latitudinalMeters: 200, longitudinalMeters: 200
        )
    }
}

#if DEBUG
struct NominationDetailsMap_Previews: PreviewProvider {
    
    static var service: Service = Service.preview
    
    static var previews: some View {
        NominationDetailsMap(nomination: service.nominations[0])
    }
}
#endif
