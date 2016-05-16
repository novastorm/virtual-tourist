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
    static let sharedInstance = CoreDataStackManager()

     // Disable default initializer
    private init() {}
    
    
    
    // MARK: - The Core Data Managed Object Context
    // adapted from http://www.cimgf.com/2014/06/08/the-core-data-stack-in-swift/
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        let mom = NSManagedObjectModel(contentsOfURL: modelURL)!
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let docURL = urls[urls.endIndex - 1]
        let storeURL = docURL.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        }
        catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        
        return managedObjectContext
    }()
    
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if !managedObjectContext.hasChanges {
            return
        }
                
        do {
            try managedObjectContext.save()
        }
        catch let error as NSError {
            print("Error saving context: \(error.localizedDescription)\n\(error.userInfo)")
            abort()
        }
    }
}



