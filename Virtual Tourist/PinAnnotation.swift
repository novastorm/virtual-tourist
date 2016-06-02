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
        var lat: Double = 0.0
        var lon: Double = 0.0
        
        CoreDataStackManager.sharedInstance.backgroundContext.performBlockAndWait { 
            lat = self.pin.latitude as! Double
            lon = self.pin.longitude as! Double
        }
        
        return CLLocationCoordinate2D(
            latitude: lat,
            longitude: lon
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