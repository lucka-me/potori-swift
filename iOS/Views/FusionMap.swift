//
//  FusionMap.swift
//  iOS
//
//  Created by Lucka on 1/6/2021.
//

import SwiftUI
import MapboxMaps
import Turf

struct FusionMap: UIViewRepresentable {
    
    private enum AnnotationMode {
        case single
        case clustring
    }
    
    fileprivate static let sourceID = "nominations"
    fileprivate static let clusteredLayerID = "\(sourceID)-clustered"
    fileprivate static let countLayerID = "\(sourceID)-count"
    fileprivate static let unclusteredLayerID = "\(sourceID)-unclustered"
    fileprivate static let padding = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    
    private static let token = "pk.eyJ1IjoibHVja2EtbWUiLCJhIjoiY2twZTQ2MDVuMDEzNzJwcDMwM3Vqbjc1ZCJ9.BgUUlHt3Wdk8aVSJr4fsvw"
    private static let color = ColorRepresentable(color: .init(hue: 0.56, saturation: 1.00, brightness: 1.00, alpha: 100))
    private static let colorLight = ColorRepresentable(color: .init(hue: 0.56, saturation: 0.80, brightness: 1.00, alpha: 100))
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var annotationManager: PointAnnotationManager? = nil
    
    private let model = FusionMapModel()
    
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
    
    func makeUIView(context: Context) -> MapView {
        let view: MapView
        if mode == .single {
            view = .init(
                frame: .zero,
                mapInitOptions: .init(
                    resourceOptions: .init(accessToken: Self.token),
                    cameraOptions: .init(
                        center: coordinates.first,
                        padding: Self.padding,
                        zoom: 16
                    ),
                    styleURI: style
                )
            )
            view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
            view.mapboxMap.onNext(.mapLoaded) { _ in
                if let coordinate = nominations.first?.coordinate {
                    let annotationManager = view.annotations.makePointAnnotationManager()
                    var annotation = PointAnnotation(coordinate: coordinate)
                    annotation.image = .default
                    annotationManager.syncAnnotations([ annotation ])
                    self.annotationManager = annotationManager
                }
            }
        } else {
            view = .init(
                frame: .zero,
                mapInitOptions: .init(
                    resourceOptions: .init(accessToken: Self.token),
                    styleURI: style
                )
            )
            view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
            view.mapboxMap.onNext(.mapLoaded) { _ in
                addAnnotations(to: view)
                model.addGestureRecognizers(to: view)
                let camera = view.mapboxMap.camera(
                    for: coordinates,
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
            if uiView.mapboxMap.style.uri != style {
                uiView.mapboxMap.style.uri = style
            }
            if mode == .clustring {
                addAnnotations(to: uiView)
            }
        }
    }
    
    private var style: StyleURI {
        colorScheme == .light ? .streets : .dark
    }
    
    private var coordinates: [ CLLocationCoordinate2D ] {
        nominations.compactMap { $0.coordinate }
    }
    
    private func addAnnotations(to view: MapView) {
        var source = GeoJSONSource()
        let features: [ Turf.Feature ] = nominations.compactMap { nomination in
            guard let coordinate = nomination.coordinate else {
                return nil
            }
            var feature = Turf.Feature(geometry: .point(.init(coordinate)))
            feature.properties = [ "title" : nomination.title ]
            return feature
        }
        source.data = .featureCollection(.init(features: features))
        source.cluster = true
        source.clusterRadius = 50
        source.clusterMaxZoom = 14

        var clusteredLayer = CircleLayer(id: Self.clusteredLayerID)
        clusteredLayer.source = Self.sourceID
        clusteredLayer.filter = Exp(.has) { "point_count" }
        clusteredLayer.circleColor = .constant(Self.colorLight)
        clusteredLayer.circleOpacity = .constant(0.6)
        clusteredLayer.circleStrokeWidth = .constant(4)
        clusteredLayer.circleStrokeColor = .constant(Self.color)
        clusteredLayer.circleRadius = .expression(Exp(.step) {
            Exp(.get) { "point_count" }
            20
            50
            30
            100
            40
        })

        var countLayer = SymbolLayer(id: Self.countLayerID)
        countLayer.source = Self.sourceID
        countLayer.filter = Exp(.has) { "point_count" }
        countLayer.textField = .expression(Exp(.get) { "point_count" })
        countLayer.textSize = .constant(12)

        var unclusteredLayer = CircleLayer(id: Self.unclusteredLayerID)
        unclusteredLayer.source = Self.sourceID
        unclusteredLayer.filter = Exp(.not) { Exp(.has) { "point_count" } }
        unclusteredLayer.circleColor = .constant(Self.colorLight)
        unclusteredLayer.circleRadius = .constant(5)
        unclusteredLayer.circleOpacity = .constant(0.6)
        unclusteredLayer.circleStrokeWidth = .constant(2)
        unclusteredLayer.circleStrokeColor = .constant(Self.color)

        let style = view.mapboxMap.style
        if style.layerExists(withId: Self.clusteredLayerID) {
            try? style.removeLayer(withId: Self.clusteredLayerID)
            try? style.removeLayer(withId: Self.countLayerID)
            try? style.removeLayer(withId: Self.unclusteredLayerID)
        }
        if style.sourceExists(withId: Self.sourceID) {
            try? style.removeSource(withId: Self.sourceID)
        }
        try? style.addSource(source, id: Self.sourceID)
        try? style.addLayer(clusteredLayer)
        try? style.addLayer(countLayer)
        try? style.addLayer(unclusteredLayer, layerPosition: .below(clusteredLayer.id))
    }
}

#if DEBUG
struct UNMapView_Previews: PreviewProvider {
    static var previews: some View {
        FusionMap([])
    }
}
#endif

fileprivate class FusionMapModel {
    var view: MapView? = nil
    
    func addGestureRecognizers(to view: MapView) {
        self.view = view
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandler(sender:))))
    }
    
    @objc private func tapHandler(sender: UITapGestureRecognizer) {
        guard let solidView = view else {
            return
        }
        let point = sender.location(in: solidView)
        tryTapClustered(at: point) { self.tryTapUnclustered(at: point) }
    }
    
    private func tryTapClustered(
        at point: CGPoint, notFoundHandler: @escaping () -> Void = { }
    ) {
        guard let solidView = view else {
            return
        }
        print(solidView.mapboxMap.style.allSourceIdentifiers)
        solidView.mapboxMap.queryRenderedFeatures(
            at: point, options: .init(layerIds: [ FusionMap.clusteredLayerID ], filter: nil)
        ) { tappedQueryResult in
            guard let _ = try? tappedQueryResult.get().first else {
                notFoundHandler()
                return
            }
            let zoom = solidView.cameraState.zoom
            let ratio = (CGFloat.pi / 2.0 - atan(zoom / 3.0)) * 0.4 + 1.0
            let camera = CameraOptions(
                center: solidView.mapboxMap.coordinate(for: point),
                padding: FusionMap.padding,
                zoom: zoom * ratio,
                bearing: solidView.cameraState.bearing,
                pitch: solidView.cameraState.pitch
            )
//            var camera = solidView.mapboxMap.camera(
//                for: /* Requires a Turf.Geometry here but we have only a MapboxMaps.Geometry */),
//                padding: FusionMap.padding,
//                bearing: solidView.cameraState.bearing,
//                pitch: solidView.cameraState.pitch
//            )
//            camera.zoom = zoom * ratio
            solidView.camera.ease(to: camera, duration: 0.5)
        }
    }
    
    private func tryTapUnclustered(
        at point: CGPoint, notFoundHandler: @escaping () -> Void = { }
    ) {
        guard let solidView = view else {
            return
        }
        solidView.mapboxMap.queryRenderedFeatures(
            at: point, options: .init(layerIds: [ FusionMap.unclusteredLayerID ], filter: nil)
        ) { result in
            guard
                let features = try? result.get(),
                let feature = features.first,
                let title = feature.feature.properties["title"] as? String,
                let viewController = UIApplication.shared.windows.first?.rootViewController
            else {
                notFoundHandler()
                return
            }
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            let action = UIAlertAction(
                title: NSLocalizedString("action.dismiss", comment: "Dismiss"),
                style: .default, handler: nil
            )
            alert.addAction(action)
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}
