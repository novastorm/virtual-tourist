//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/22/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var imageData: Data?
    @NSManaged var imageURLString: String?
    @NSManaged var pin: Pin?

}
