//
//  FusionMap.swift
//  iOS
//
//  Created by Lucka on 1/6/2021.
//

import SwiftUI
import MapboxMaps

struct FusionMap: UIViewRepresentable {
    
    private enum AnnotationMode {
        case single
        case clustring
    }
    
    class AnnotationData {
        var longitude: Double
        var latitude: Double
        var title: String
        var color: Color
        
        init(_ longitude: Double, _ latitude: Double, _ title: String, _ color: Color) {
            self.longitude = longitude
            self.latitude = latitude
            self.title = title
            self.color = color
        }
        
        var coordinate: CLLocationCoordinate2D {
            .init(latitude: latitude, longitude: longitude)
        }
    }
    
    class Coordinator {
        
        var annotationManager: PointAnnotationManager? = nil
        
        func addGestureRecognizer(to view: MapView) {
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandler)))
        }
        
        @objc private func tapHandler(sender: UITapGestureRecognizer) {
            guard let solidView = sender.view as? MapView else { return }
            let location = sender.location(in: solidView)
            
            Task {
                guard
                    let quiredFeatures = try? await solidView.mapboxMap.queryRenderedFeatures(
                        at: location, options: .init(layerIds: [ FusionMap.clusteredLayerID ], filter: nil)
                    ),
                    let feature = quiredFeatures.first?.feature,
                    case let .point(point) = feature.geometry,
                    let featureExtension = try? await solidView.mapboxMap.queryFeatureExtension(
                        for: FusionMap.sourceID,
                        feature: feature,
                        extension: "supercluster",
                        extensionField: "expansion-zoom"
                    ),
                    let zoom = featureExtension.value as? Int64
                else {
                    return
                }
                
                let camera = await CameraOptions(
                    center: point.coordinates,
                    padding: FusionMap.padding,
                    zoom: .init(zoom),
                    bearing: solidView.cameraState.bearing,
                    pitch: solidView.cameraState.pitch
                )
                await solidView.camera.ease(to: camera, duration: 0.5)
            }
        }
    }
    
    fileprivate static let sourceID = "annotations"
    fileprivate static let clusteredLayerID = "\(sourceID)-clustered"
    fileprivate static let countLayerID = "\(sourceID)-count"
    fileprivate static let unclusteredLayerID = "\(sourceID)-unclustered"
    fileprivate static let titleLayerID = "\(sourceID)-title"
    fileprivate static let padding = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    
    private static let resourceOptions = ResourceOptions(accessToken: "pk.eyJ1IjoibHVja2EtbWUiLCJhIjoiY2twZTQ2MDVuMDEzNzJwcDMwM3Vqbjc1ZCJ9.BgUUlHt3Wdk8aVSJr4fsvw")
    private static let clusterColor = StyleColor(.init(hue: 0.56, saturation: 1.00, brightness: 1.00, alpha: 1.0))
    
    private let annotations: [ AnnotationData ]
    private let features: [ Feature ]
    private let camera: CameraOptions
    
    private let mode: AnnotationMode
    
    init(_ annotations: [ AnnotationData ]) {
        self.annotations = annotations
        var north = -91.0
        var south = 91.0
        var east = -181.0
        var west = 181.0
        
        self.features = annotations.map { annotation in
            if north < annotation.latitude { north = annotation.latitude }
            if south > annotation.latitude { south = annotation.latitude }
            if east < annotation.longitude { east = annotation.longitude }
            if west > annotation.longitude { west = annotation.longitude }
            
            var feature = Feature(geometry: .point(.init(annotation.coordinate)))
            feature.properties = [
                "title" : .string(annotation.title),
                "color" : .string(annotation.color.rgbaString)
            ]
            return feature
        }
        
        self.camera = .init(center: .init(latitude: (north + south) / 2, longitude: (east + west) / 2))
        self.mode = .clustring
    }
    
    init(_ annotation: AnnotationData) {
        self.annotations = [ annotation ]
        self.features = []
        self.camera = .init(center: annotation.coordinate, padding: Self.padding, zoom: 16)
        self.mode = .single
    }
    
    func makeCoordinator() -> Coordinator {
        .init()
    }
    
    func makeUIView(context: Context) -> MapView {
        let options = MapInitOptions(
            resourceOptions: Self.resourceOptions,
            cameraOptions: camera,
            styleURI: Self.styleURI(for: context.environment.colorScheme)
        )
        let view = MapView(frame: .zero, mapInitOptions: options)
        view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        view.mapboxMap.onNext(.mapLoaded) { _ in
            if mode == .single {
                if let coordinate = annotations.first?.coordinate {
                    let annotationManager = view.annotations.makePointAnnotationManager()
                    var annotation = PointAnnotation(coordinate: coordinate)
                    annotation.image = .init(image: .init(named: "Pin")!, name: "pin")
                    annotation.iconAnchor = .bottom
                    annotationManager.annotations = [ annotation ]
                    context.coordinator.annotationManager = annotationManager
                }
            } else {
                addAnnotations(to: view)
                context.coordinator.addGestureRecognizer(to: view)
                let camera = view.mapboxMap.camera(
                    for: annotations.map { $0.coordinate },
                    padding: Self.padding,
                    bearing: 0,
                    pitch: 0
                )
                view.camera.fly(to: camera)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: MapView, context: Context) {
        uiView.mapboxMap.onNext(.mapLoaded) { _ in
            let styleURI = Self.styleURI(for: context.environment.colorScheme)
            if uiView.mapboxMap.style.uri != styleURI {
                uiView.mapboxMap.style.uri = styleURI
            }
            if mode == .clustring {
                addAnnotations(to: uiView)
            }
        }
    }
    
    private static func styleURI(for colorScheme: ColorScheme) -> StyleURI {
        colorScheme == .light ? .streets : .dark
    }
    
    private func addAnnotations(to view: MapView) {
        let featureCollection = FeatureCollection(features: features)
        
        let style = view.mapboxMap.style
        if style.sourceExists(withId: Self.sourceID) {
            try? style.updateGeoJSONSource(withId: Self.sourceID, geoJSON: .featureCollection(featureCollection))
            return
        }
        
        var source = GeoJSONSource()
        source.data = .featureCollection(featureCollection)
        source.cluster = true
        source.generateId = true
        source.clusterRadius = 50
        source.clusterMaxZoom = 14
        try? style.addSource(source, id: Self.sourceID)
        
        var clusteredLayer = CircleLayer(id: Self.clusteredLayerID)
        clusteredLayer.source = Self.sourceID
        clusteredLayer.filter = Exp(.has) { "point_count" }
        clusteredLayer.circleColor = .constant(Self.clusterColor)
        clusteredLayer.circleOpacity = .constant(0.6)
        clusteredLayer.circleStrokeWidth = .constant(4)
        clusteredLayer.circleStrokeColor = .constant(Self.clusterColor)
        clusteredLayer.circleRadius = .expression(Exp(.interpolate) {
            Exp(.linear)
            Exp(.get) { "point_count" }
            5
            10
            50
            30
            200
            50
        })

        var countLayer = SymbolLayer(id: Self.countLayerID)
        countLayer.source = Self.sourceID
        countLayer.filter = Exp(.has) { "point_count" }
        countLayer.textField = .expression(Exp(.get) { "point_count" })
        countLayer.textSize = .constant(12)

        var unclusteredLayer = CircleLayer(id: Self.unclusteredLayerID)
        unclusteredLayer.source = Self.sourceID
        unclusteredLayer.filter = Exp(.not) { Exp(.has) { "point_count" } }
        unclusteredLayer.circleColor = .expression(Exp(.get) { "color" })
        unclusteredLayer.circleRadius = .constant(5)
        unclusteredLayer.circleOpacity = .constant(0.6)
        unclusteredLayer.circleStrokeWidth = .constant(2)
        unclusteredLayer.circleStrokeColor = .expression(Exp(.get) { "color" })
        
        var titleLayer = SymbolLayer(id: Self.titleLayerID)
        titleLayer.source = Self.sourceID
        titleLayer.filter = Exp(.has) { "title" }
        titleLayer.textField = .expression(Exp(.get) { "title" })
        titleLayer.textAnchor = .constant(.top)
        titleLayer.textColor = .constant(.init(.white))
        titleLayer.textHaloColor = .constant(.init(.black))
        titleLayer.textHaloWidth = .constant(1)
        titleLayer.textOffset = .constant([ 0, 0.6 ])
        titleLayer.textSize = .constant(12)
        
        try? style.addLayer(clusteredLayer)
        try? style.addLayer(countLayer)
        try? style.addLayer(unclusteredLayer, layerPosition: .below(clusteredLayer.id))
        try? style.addLayer(titleLayer, layerPosition: .below(unclusteredLayer.id))
    }
}

#if DEBUG
struct UNMapView_Previews: PreviewProvider {
    static var previews: some View {
        FusionMap(.init(122, 31, "Test", .blue))
    }
}
#endif

fileprivate extension Color {
    var rgbaString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return "rgba(\(Int(r * 255)),\(Int(g * 255)),\(Int(b * 255)),\(a * 255))"
    }
}

extension MapboxMap {
    @MainActor
    func queryRenderedFeatures(at point: CGPoint, options: RenderedQueryOptions? = nil) async throws -> [ QueriedFeature ] {
        return try await withCheckedThrowingContinuation { continuation in
            queryRenderedFeatures(at: point, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func queryFeatureExtension(
        for sourceId: String,
        feature: Feature,
        extension: String,
        extensionField: String,
        args: [String: Any]? = nil
    ) async throws -> FeatureExtensionValue {
        return try await withCheckedThrowingContinuation { continuation in
            queryFeatureExtension(
                for: sourceId,
                feature: feature,
                extension: `extension`,
                extensionField: extensionField,
                args: args
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
}
