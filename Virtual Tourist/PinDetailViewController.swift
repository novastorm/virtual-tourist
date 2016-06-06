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
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    let newCollectionButtonTitleDefault = "New Collection"
    let newCollectionButtonTitleDownloading = "Downloading (25)"
    let viewScaleRadiusKm = 50
    let numberOfStaticCells = 1
    
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
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
        var numberOfPendingPhotos = 0
        
        for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
            if photo.imageData == nil {
                numberOfPendingPhotos += 1
            }
        }
        
        return (numberOfPendingPhotos == 0, numberOfPendingPhotos)
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
            let potentialPages = data[FlickrClient.Photos.Pages] as! Int
            // Flickr returns at most 4000 images, determine adjusted maximum number of pages.
            let maxPages = FlickrClient.Config.MaxPhotosReturned / FlickrClient.Config.PerPage
            let pages = min(potentialPages, maxPages)
            
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
        CoreDataStackManager.sharedInstance.performAsyncBackgroundBatchOperation { (workerContext) in
            for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
                let photoInContext = try! workerContext.existingObjectWithID(photo.objectID) as! Photo
                if photoInContext.imageData == nil {
                    photoInContext.getImageData()
                    break
                }
            }
            self.saveContext()
        }
    }
    
    func clearPhotos() {
        for object in self.fetchedResultsController.fetchedObjects as! [Photo] {
            self.sharedMainContext.deleteObject(object)
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
        return fetchedResultsController.sections!.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects + numberOfStaticCells
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cellIdentifier: String
        var cell: UICollectionViewCell
        
        if indexPath.item == 0 {
            cellIdentifier = "Map"
            let mapCell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! MapCollectionViewCell
            
            configureMapCell(mapCell, atIndexPath: indexPath)
            cell = mapCell
        }
        else {
            cellIdentifier = "PinPhoto"
            let pinPhotoCell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PinPhotoCollectionViewCell
            
            configurePinPhotoCell(pinPhotoCell, atIndexPath: indexPath)
            cell = pinPhotoCell
        }
        
        return cell
    }
    
    func configureMapCell(cell: MapCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let lat = annotation.coordinate.latitude
        let lon = annotation.coordinate.longitude
        let radius = distanceInMeters(kilometers: Double(viewScaleRadiusKm))
        
        let coordinate = CLLocationCoordinate2DMake(lat, lon)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, radius, radius)
        
        cell.mapView.setRegion(region, animated: true)
        
        cell.mapView.removeAnnotations(cell.mapView.annotations)
        cell.mapView.addAnnotation(self.annotation)

    }
    
    func configurePinPhotoCell(cell: PinPhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {

        let indexPathAdjusted = NSIndexPath(forItem: indexPath.item - numberOfStaticCells, inSection: 0)

        // use adjusted indexPath for fetching an object
        let photo = fetchedResultsController.objectAtIndexPath(indexPathAdjusted) as! Photo
        var imageData: NSData!
        
        imageData = photo.imageData
        
        cell.showLoading()
        guard (imageData != nil) else {
            CoreDataStackManager.sharedInstance.performAsyncBackgroundBatchOperation { (workerContext) in
                let photoInContext = workerContext.objectWithID(photo.objectID) as! Photo
                let pendingImageData = photoInContext.getImageData()
                performUIUpdatesOnMain {
                    // use normal indexPath for cell selection
                    if let cellToUpdate = self.collectionView.cellForItemAtIndexPath(indexPath) as? PinPhotoCollectionViewCell {
                        cellToUpdate.showImage(pendingImageData)
                    }
                }
                self.saveContext()
            }
            
            return
        }
        
        cell.showImage(imageData)
    }
}


// MARK: - Collection View Delegate

extension PinDetailViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        guard indexPath.item != 0 else {
            return
        }
        
        guard getPhotoDownloadStatus().completed else {
            return
        }
        
        
        let indexPathAdjusted = NSIndexPath(forItem: indexPath.item - numberOfStaticCells, inSection: 0)


        CoreDataStackManager.sharedInstance.performBackgroundBatchOperation { (workerContext) in
            let photo = self.fetchedResultsController.objectAtIndexPath(indexPathAdjusted) as! Photo
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
            let newIndexPathAdjusted = NSIndexPath(forItem: newIndexPath!.item + numberOfStaticCells, inSection: 0)
            insertedIndexPaths.append(newIndexPathAdjusted)
        case .Delete:
            let indexPathAdjusted = NSIndexPath(forItem: indexPath!.item + numberOfStaticCells, inSection: 0)
            deletedIndexPaths.append(indexPathAdjusted)
        case .Update:
            let indexPathAdjusted = NSIndexPath(forItem: indexPath!.item + numberOfStaticCells, inSection: 0)
            updatedIndexPaths.append(indexPathAdjusted)
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


// MARK: - UICollectionViewDelegateFlowLayout

extension PinDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let width = floor(collectionView.frame.size.width)
        let height = floor(collectionView.frame.size.height)
        
        let numberAcross:CGFloat = ((width < height) ? 3.0 : 5.0)
        
        let itemSize = (width - ((numberAcross - 1) * flowLayout.minimumLineSpacing)) / numberAcross
        
        return CGSize(width: itemSize, height: itemSize)
    }
}
