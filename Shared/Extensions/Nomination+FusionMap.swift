//
//  Nomination+FusionMap.swift
//  Potori
//
//  Created by Lucka on 16/10/2021.
//

import Foundation

extension Nomination {
    var annotation: FusionMap.AnnotationData? {
        return hasLngLat ? .init(longitude, latitude, title, statusData.color) : nil
    }
}
