//
//  FusionMap.swift
//  macOS
//
//  Created by Lucka on 2/6/2021.
//

import SwiftUI
import MapKit

struct FusionMap: NSViewRepresentable {
    
    private enum AnnotationMode {
        case single
        case clustring
    }
    
    private let nominations: [ Nomination ]
    private let mode: AnnotationMode
    
    init(_ nominations: [ Nomination ]) {
        self.nominations = nominations
        self.mode = .clustring
    }
    
    init(_ nomination: Nomination) {
        self.nominations = [ nomination ]
        self.mode = .single
    }
    
    func makeNSView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.isZoomEnabled = true
        view.isRotateEnabled = true
        view.isScrollEnabled = true
        updateNSView(view, context: context)
        return view
    }
    
    func updateNSView(_ nsView: MKMapView, context: Context) {
        nsView.removeAnnotations(nsView.annotations)
        if mode == .single {
            guard let coordinate = coordinates.first else {
                return
            }
            DispatchQueue.main.async {
                nsView.setCamera(.init(lookingAtCenter: coordinate, fromDistance: 100, pitch: 0, heading: 0), animated: true)
            }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            nsView.addAnnotation(annotation)
        } else {
            nsView.showsCompass = true
            nsView.showsZoomControls = true
            var minLng = 181.0
            var maxLng = -181.0
            var minLat = 91.0
            var maxLat = -91.0
            let annotations: [ MKPointAnnotation ] = nominations.compactMap { nomination in
                guard let coordinate = nomination.coordinate else {
                    return nil
                }
                minLng = min(minLng, nomination.longitude)
                maxLng = max(maxLng, nomination.longitude)
                minLat = min(minLat, nomination.latitude)
                maxLat = max(maxLat, nomination.latitude)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = nomination.title
                return annotation
            }
            nsView.addAnnotations(annotations)
            if (minLng < 181) {
                let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: maxLat, longitude: minLng))
                let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: minLat, longitude: maxLng))
                let rect = MKMapRect(
                    x: topLeft.x,
                    y: topLeft.y,
                    width: bottomRight.x - topLeft.x,
                    height: bottomRight.y - topLeft.y
                )
                DispatchQueue.main.async {
                    nsView.setRegion(.init(rect), animated: true)
                }
            }
        }
    }
    
    private var coordinates: [ CLLocationCoordinate2D ] {
        nominations.compactMap { $0.coordinate }
    }
}

#if DEBUG
struct FusionMap_Previews: PreviewProvider {
    static var previews: some View {
        FusionMap([])
    }
}
#endif
