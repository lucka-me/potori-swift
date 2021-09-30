//
//  GeomaticData.swift
//  Potori
//
//  Created by Lucka on 30/9/2021.
//
import CoreLocation
import SwiftUI

struct GeomaticData {
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
