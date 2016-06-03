//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/19/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {
    
    struct Keys {
        static let ImageData = "imageData"
        static let ImageURLString = "imageURL"
        static let Pin = "pin"
    }
    
    convenience init(imageURLString: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imageURLString = imageURLString
    }
    
    func getImageData() -> NSData {
        let imageURL = NSURL(string: imageURLString!)
        imageData = NSData(contentsOfURL: imageURL!)
        
        return imageData!
    }
}
