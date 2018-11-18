import CoreData

// MARK:  - Main
final class CoreDataStack_v2: CoreDataStack {
    
    let container: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext!
    
    var mainContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    init(container: NSPersistentContainer) {
        self.container = container
        backgroundContext = container.newBackgroundContext()
    }
    
    func configureContexts() {
        mainContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        mainContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func load(completionHandler: (() -> Void)? = nil) {
        container.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            self.configureContexts()
            completionHandler?()
        }
    }
    
    func clearDatabase() throws {
        let persistentStores = container.persistentStoreCoordinator.persistentStores
        for persistentStore in persistentStores {
            let url = container.persistentStoreCoordinator.url(for: persistentStore)
            try container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: persistentStore.type, options: nil)
        }
    }
    
    func getScratchContext(named name: String) -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.parent = nil
        return context
    }

    func getTemporaryContext(named name: String) -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    func performBackgroundBatchOperation(_ batch: @escaping CoreDataStack.BatchTask) {
        return container.performBackgroundTask(batch)
    }

    func saveTemporaryContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        }
        catch {
            print(error)
            fatalError("Error while saving \(context.name ?? "temporary") context")
        }
    }

    func saveMainContext() {
        performUIUpdatesOnMain {
            guard self.mainContext.hasChanges else {
                return
            }
            if let parent = self.mainContext.parent {
                print(parent)
            }
            do {
                try self.mainContext.save()
            }
            catch {
                print(error)
                fatalError("Error while saving main context")
            }
        }
    }

    func savePersistingContext() {
        // empty
    }

    func autoSave(_ interval: TimeInterval = 60) {
        guard interval > 0 else {
            print("Positive interval required")
            return
        }

        saveMainContext()
            
        let time = DispatchTime.now() + interval
        
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            self.autoSave(interval)
        })
    }
}

