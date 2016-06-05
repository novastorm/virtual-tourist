//
//  PinDetailViewController.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/18/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class PinDetailViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    let newCollectionButtonTitleDefault = "New Collection"
    let newCollectionButtonTitleDownloading = "Downloading (25)"
    let viewScaleRadiusKm = 50
    
    var annotation: PinAnnotation!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    
    // MARK: - Core Data convenience methods
    
    var sharedMainContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.mainContext
    }
    
    var sharedBackgroundContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.backgroundContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.annotation.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedMainContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance.saveMainContext()
    }
    
    func saveTempContext(context: NSManagedObjectContext) {
        CoreDataStackManager.sharedInstance.saveTempContext(context)
    }
    
    
    // MARK: - View Cycle
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        newCollectionButton.possibleTitles = [
            newCollectionButtonTitleDefault,
            newCollectionButtonTitleDownloading
        ]
        newCollectionButton.title = newCollectionButtonTitleDefault
        newCollectionButton.enabled = false
        
        do {
            try fetchedResultsController.performFetch()
        }
        catch let error as NSError {
            print("Error performining initial fetch: \(error)")
        }
        
        fetchedResultsController.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(saveContext), name: CoreDataStackNotifications.ImportingTaskDidFinish.rawValue, object: nil)
        
        
        var numberOfPhotos = 0
        
        numberOfPhotos = self.annotation.pin.photos!.count
        
        if numberOfPhotos == 0 {
            self.getPhotos()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let lat = annotation.coordinate.latitude
        let lon = annotation.coordinate.longitude
        let radius = distanceInMeters(kilometers: Double(viewScaleRadiusKm))
        
        let coordinate = CLLocationCoordinate2DMake(lat, lon)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, radius, radius)
        
        mapView.setRegion(region, animated: true)
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotation(self.annotation)
        
        let (state, remaining) = getPhotoDownloadStatus()
        enableNewCollectionButton(state, remaining: remaining)
    }
    
    // MARK: - Actions
    
    @IBAction func getNewCollection(sender: AnyObject) {
        newCollectionButton.enabled = false
        clearPhotos()
        getPhotos()
    }
    
    // MARK: - Helpers
    
    func getPhotoDownloadStatus() -> (completed: Bool, remaining: Int) {
        var numberOfPhotos = 0
        var numberOfPendingPhotos = 0
        
        numberOfPhotos = (self.annotation.pin.photos?.count)!
        for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
            if photo.imageData == nil {
                numberOfPendingPhotos += 1
            }
        }
        
        return (numberOfPhotos > 0 && numberOfPendingPhotos == 0, numberOfPendingPhotos)
    }
    
    func getPhotos() {
        var lat: Double!
        var lon: Double!
        
        lat = self.annotation.pin.latitude as! Double
        lon = self.annotation.pin.longitude as! Double
        
        FlickrClient.sharedInstance.searchByLocation(latitude: lat, longitude: lon) { (results, error) in
            if let error = error {
                print(error)
                return
            }
            
            let data = results![FlickrClient.ResponseKeys.Photos] as! [String: AnyObject]
            let pages = data[FlickrClient.Photos.Pages] as! Int
            let randomPage = random(pages, start: 1)
            
            FlickrClient.sharedInstance.searchByLocation(latitude: lat, longitude: lon, page: randomPage) { (results, error) in
                
                if let error = error {
                    print(error)
                    return
                }
                
                guard let photoResults = results?[FlickrClient.ResponseKeys.Photos]??[FlickrClient.Photos.Photo] as? [[String:AnyObject]] else {
                    print("Cannot find photo list in Photos object")
                    return
                }
                
                CoreDataStackManager.sharedInstance.performAsyncBackgroundBatchOperation { (workerContext) in
                    let pin = workerContext.objectWithID(self.annotation.pin.objectID) as! Pin
                    
                    for record in photoResults {
                        let imageURLString = record[FlickrClient.Photo.MediumURL] as! String
                        let photo = Photo(imageURLString: imageURLString, context: workerContext)
                        photo.pin = pin
                    }
                }
            }
        }
    }
    
    func downloadAnImage() {
        for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
            if photo.imageData == nil {
                photo.getImageData()
                break
            }
        }
    }
    
    func clearPhotos() {
        CoreDataStackManager.sharedInstance.performBackgroundBatchOperation { (workerContext) in
            for object in self.fetchedResultsController.fetchedObjects! {
                let objectInContext = workerContext.objectWithID(object.objectID)
                workerContext.deleteObject(objectInContext)
            }
        }
        saveContext()
    }
    
    func enableNewCollectionButton(state: Bool, remaining count: Int = 0) {
        performUIUpdatesOnMain {
            if !state {
                self.newCollectionButton.title = "Downloading (\(count))"
            }
            else {
                self.newCollectionButton.title = self.newCollectionButtonTitleDefault
            }
            
            self.newCollectionButton.enabled = state
        }
    }
}


// MARK: - Collection View Data Source

extension PinDetailViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let identifier = "PinPhoto"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! PinPhotoCollectionViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: PinPhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        var imageData: NSData!
        
        imageData = photo.imageData
        
        cell.showLoading()
        guard (imageData != nil) else {
            CoreDataStackManager.sharedInstance.performAsyncBackgroundBatchOperation { (workerContext) in
                let photoInContext = workerContext.objectWithID(photo.objectID) as! Photo
                let pendingImageData = photoInContext.getImageData()
                performUIUpdatesOnMain {
                    if let cellToUpdate = self.collectionView.cellForItemAtIndexPath(indexPath) as? PinPhotoCollectionViewCell {
                        cellToUpdate.showImage(pendingImageData)
                    }
                }
            }
            
            return
        }
        
        cell.showImage(imageData)
    }
}


// MARK: - Collection View Delegate

extension PinDetailViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        guard getPhotoDownloadStatus().completed else {
            return
        }
        

        CoreDataStackManager.sharedInstance.performBackgroundBatchOperation { (workerContext) in
            let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            let photoInContext = workerContext.objectWithID(photo.objectID)
            workerContext.deleteObject(photoInContext)
        }
        
        saveContext()
    }
}


// MARK: - Fetched Results Controller Delegate

extension PinDetailViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        case .Update:
            updatedIndexPaths.append(indexPath!)
        case .Move:
            fallthrough
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        self.collectionView.performBatchUpdates( { () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion: { (success) in
                if !self.getPhotoDownloadStatus().completed {
                    self.downloadAnImage()
                }
            }
        )
        
        let (state, remaining) = getPhotoDownloadStatus()
        enableNewCollectionButton(state, remaining: remaining)
    }
}