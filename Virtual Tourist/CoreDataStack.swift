//
//  CoreDataStackProtocol.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 3/15/18.
//  Copyright © 2016 Adland Lee. All rights reserved.
//
import CoreData

// MARK:  - Notifications
extension Notification.Name {
    static let CoreDataStackImportingTaskDidFinishNotification = Notification.Name("CoreDataStackImportingTaskDidFinish")
}

protocol CoreDataStack {

    // MARK:  - TypeAliases
    typealias BatchTask=(_ workerContext: NSManagedObjectContext) -> ()

    // MARK: - Properties
    var mainContext: NSManagedObjectContext { get }
        
    // MARK: - Removing data
    func clearDatabase() throws
    
    // MARK: - Operations
    
    func getScratchContext(named name: String) -> NSManagedObjectContext

    func getTemporaryContext(named name: String) -> NSManagedObjectContext

    func performBackgroundBatchOperation(_ batch: @escaping BatchTask)
    
    func saveTemporaryContext(_ context: NSManagedObjectContext)

    func saveMainContext()
    
    func savePersistingContext()
    
    func autoSave(_ interval : TimeInterval)
}

