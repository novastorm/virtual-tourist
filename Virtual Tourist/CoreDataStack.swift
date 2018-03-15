//
//  CoreDataStackProtocol.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 3/15/18.
//  Copyright © 2016 Adland Lee. All rights reserved.
//
import CoreData

protocol CoreDataStack {
    
    typealias BatchTask=(_ workerContext: NSManagedObjectContext) -> ()
    
    // MARK:  - Properties
    var mainContext: NSManagedObjectContext { get }
    
    // MARK:  - Initializers
    init?(modelName: String)
    
    // MARK:  - Removing data
    func clearDatabase() throws
    
    func getScratchContext(named name: String) -> NSManagedObjectContext

    func getTemporaryContext(named name: String) -> NSManagedObjectContext

    func performBackgroundBatchOperation(_ batch: @escaping BatchTask)
    
    func saveTemporaryContext(_ context: NSManagedObjectContext)

    func saveMainContext()
    
    func savePersistingContext()
    
    func autoSave(_ delayInSeconds : Int)
}












