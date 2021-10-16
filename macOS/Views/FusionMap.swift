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
    
    class AnnotationData : NSObject, MKAnnotation {
        var longitude: Double
        var latitude: Double
        var title: String?
        var color: Color
        
        init(_ longitude: Double, _ latitude: Double, _ title: String, _ color: Color) {
            self.longitude = longitude
            self.latitude = latitude
            self.title = title
            self.color = color
        }
        
        @objc dynamic var coordinate: CLLocationCoordinate2D {
            .init(latitude: latitude, longitude: longitude)
        }
    }
    
    private let annotations: [ AnnotationData ]
    private let camera: CameraRepresentable
    
    private let mode: AnnotationMode
    
    init(_ annotations: [ AnnotationData ]) {
        self.annotations = annotations
        var west = 181.0
        var east = -181.0
        var south = 91.0
        var north = -91.0
        for annotation in annotations {
            if north < annotation.latitude { north = annotation.latitude }
            if south > annotation.latitude { south = annotation.latitude }
            if east < annotation.longitude { east = annotation.longitude }
            if west > annotation.longitude { west = annotation.longitude }
        }
        let region: MKCoordinateRegion
        if west < 180.5 {
            let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: north, longitude: west))
            let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: south, longitude: east))
            let rect = MKMapRect(
                x: topLeft.x,
                y: topLeft.y,
                width: bottomRight.x - topLeft.x,
                height: bottomRight.y - topLeft.y
            )
            region = .init(rect)
        } else {
            region = .init()
        }
        camera = ClusterCamera(region)
        
        self.mode = .clustring
    }
    
    init(_ annotation: AnnotationData) {
        self.annotations = [ annotation ]
        self.camera = SingleCamera(.init(lookingAtCenter: annotation.coordinate, fromDistance: 100, pitch: 0, heading: 0))
        self.mode = .single
    }
    
    func makeNSView(context: Context) -> MKMapView {
        let view = MKMapView()
        camera.set(to: view)
        view.isZoomEnabled = true
        view.isRotateEnabled = true
        view.isScrollEnabled = true
        if mode == .clustring {
            view.showsCompass = true
            view.showsZoomControls = true
            view.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
            view.register(UnclusteredAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        }
        addAnnotations(to: view)
        return view
    }
    
    func updateNSView(_ nsView: MKMapView, context: Context) {
//        nsView.removeAnnotations(nsView.annotations)
//        addAnnotations(to: nsView)
    }
    
    private func addAnnotations(to view: MKMapView) {
        if mode == .single {
            guard let coordinate = annotations.first?.coordinate else { return }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            view.addAnnotation(annotation)
        } else {
            view.addAnnotations(annotations)
        }
    }
}

#if DEBUG
struct FusionMap_Previews: PreviewProvider {
    static var previews: some View {
        FusionMap([])
    }
}
#endif

fileprivate protocol CameraRepresentable {
    func set(to view: MKMapView)
}

fileprivate struct SingleCamera : CameraRepresentable {
    let camera: MKMapCamera
    
    init(_ camera: MKMapCamera) {
        self.camera = camera
    }
    
    func set(to view: MKMapView) {
        view.camera = camera
    }
}

fileprivate struct ClusterCamera: CameraRepresentable {
    let region: MKCoordinateRegion
    
    init(_ region: MKCoordinateRegion) {
        self.region = region
    }
    
    func set(to view: MKMapView) {
        view.region = region
    }
}

fileprivate class ClusterAnnotationView: MKAnnotationView {
    
    private static let fillColor = NSColor(hue: 0.56, saturation: 1.0, brightness: 1.0, alpha: 0.6)
    private static let strokeColor = NSColor(hue: 0.56, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    
    private static let textAttributes = [
        NSAttributedString.Key.foregroundColor: NSColor.black,
        NSAttributedString.Key.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
    ]
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        guard let cluster = annotation as? MKClusterAnnotation else { return }
        let count = cluster.memberAnnotations.count
        let size: CGFloat
        if count < 50 {
            size = 40
        } else if count < 100 {
            size = 60
        } else {
            size = 80
        }
        image = .init(size: .init(width: size, height: size), flipped: false) { rect in
            Self.strokeColor.setStroke()
            Self.fillColor.setFill()
            let circleSize = size - 4
            let circle = NSBezierPath(ovalIn: .init(x: 2, y: 2, width: circleSize, height: circleSize))
            circle.lineWidth = 4
            circle.fill()
            circle.stroke()
            
            let text = "\(count)"
            let textSize = text.size(withAttributes: Self.textAttributes)
            let center = size / 2
            let textX = center - textSize.width / 2
            let textY = center - textSize.height / 2
            text.draw(
                in: .init(x: textX, y: textY, width: textSize.width, height: textSize.height),
                withAttributes: Self.textAttributes
            )
            return true
        }
    }
}

class UnclusteredAnnotationView: MKMarkerAnnotationView {

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "annotations"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        guard let data = annotation as? FusionMap.AnnotationData else { return }
        markerTintColor = .init(data.color)
    }
}
