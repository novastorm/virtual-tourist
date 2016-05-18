//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/12/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {

    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
    
    convenience init(lat: Double, lon: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = lat
        longitude = lon
    }
}
