//
//  PinAnnotation.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/20/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import MapKit


class PinAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: pin.latitude as Double,
            longitude: pin.longitude as Double
        )
    }
    var title: String?
    var subtitle: String?
    var pin: Pin
    
    init(withPin pin: Pin, title: String? = nil, subtitle: String? = nil) {
        self.pin = pin
        self.title = title
        self.subtitle = subtitle
    }
}