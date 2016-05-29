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
    @IBOutlet weak var reloadImagesButton: UIBarButtonItem!
    
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
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.context
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.annotation.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance.save()
    }
    
    
    // MARK: - View Cycle
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {

        do {
            try fetchedResultsController.performFetch()
        }
        catch let error as NSError {
            print("Error performining initial fetch: \(error)")
        }
        
        fetchedResultsController.delegate = self
        
        if annotation.pin.photos!.count == 0 {
            getPhotos()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let lat = annotation.coordinate.latitude
        let lon = annotation.coordinate.longitude
        let radius = 100.0
        
        let coordinate = CLLocationCoordinate2DMake(lat, lon)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, radius, radius)

        mapView.setRegion(region, animated: true)

        performUIUpdatesOnMain {
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotation(self.annotation)
            self.reloadImagesButton.enabled = self.isPhotoDownloadComplete()
        }
    }

    // MARK: - Actions
    
    @IBAction func reloadImages(sender: AnyObject) {
        clearPhotos()
        getPhotos()
    }
    
    // MARK: - Helpers
    
    func isPhotoDownloadComplete() -> Bool {
        var count = 0
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            if photo.imageData == nil {
                count += 1
            }
        }
        
        return annotation.pin.photos?.count > 0 && count == 0
    }
    
    func getPhotos() {
        let lat = annotation.pin.latitude as! Double
        let lon = annotation.pin.longitude as! Double

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
                
                guard let photos = results?[FlickrClient.ResponseKeys.Photos]??[FlickrClient.Photos.Photo] as? [[String:AnyObject]] else {
                    print("Cannot find photo list in Photos object")
                    return
                }
                
                let _ = photos.map() { (photo: [String: AnyObject]) -> Photo in
                    let imageURLString = photo[FlickrClient.Photo.MediumURL] as! String
                    let photo = Photo(imageURLString: imageURLString, context: self.sharedContext)
                    photo.pin = self.annotation.pin
                    
                    return photo
                }
                
                self.saveContext()
            }
        }
    }
    
    func clearPhotos() {
        CoreDataStackManager.sharedInstance.performBackgroundBatchOperation { (workerContext) in
            for object in self.fetchedResultsController.fetchedObjects! {
                self.sharedContext.deleteObject(object as! NSManagedObject)
            }
        }
        reloadImagesButton.enabled = false
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
        
        guard photo.imageData != nil else {
            cell.showLoading()
            CoreDataStackManager.sharedInstance.performBackgroundBatchOperation { (workerContext) in
                photo.getImageData()
                if let cellToUpdate = self.collectionView.cellForItemAtIndexPath(indexPath) as? PinPhotoCollectionViewCell {
                    performUIUpdatesOnMain {
                        cellToUpdate.showImage(photo.imageData!)
                    }
                }
            }
            return
        }
        
        cell.showImage(photo.imageData!)
    }
}


// MARK: - Collection View Delegate

extension PinDetailViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        sharedContext.deleteObject(photo)
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
//        case .Move:
//            break
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {

        collectionView.performBatchUpdates( { () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
        }, completion: nil)
        
        self.reloadImagesButton.enabled = self.isPhotoDownloadComplete()
    }
}