//
//  CoreDataStackManager.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/12/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import Foundation
import CoreData

private let SQLITE_FILE_NAME = "VirtualTourist.sqlite"

class CoreDataStackManager {
    
    // MARK: - Shared Instance
    
    /**
     *  This class variable provides an easy way to get access
     *  to a shared instance of the CoreDataStackManager class.
     */
    static let sharedInstance = CoreDataStack(modelName: "Virtual_Tourist")!

     // Disable default initializer
    fileprivate init() {}

}



