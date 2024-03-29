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

struct PinDetailViewControllerDependency {
    
    var coreDataStack: CoreDataStack!
    var flickrClient: FlickrClient!
    
    init(
        coreDataStack: CoreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack,
        flickrClient: FlickrClient = (UIApplication.shared.delegate as! AppDelegate).flickrClient
    ) {
        self.coreDataStack = coreDataStack
        self.flickrClient = flickrClient
    }
}

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
    var selectedIndexes = [IndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!

    let dependencies: PinDetailViewControllerDependency!
    
    // MARK: - Core Data
    
    var coreDataStack: CoreDataStack {
        return dependencies.coreDataStack
    }

    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {
        
        let fetchRequest = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.annotation.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController as! NSFetchedResultsController<Photo>
    }()


    // MARK: - Flickr
    
    var flickrClient: FlickrClient {
        return dependencies.flickrClient
    }


    // MARK: - View Cycle
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    init?(coder aDecoder: NSCoder? = nil,
          dependencies: PinDetailViewControllerDependency = PinDetailViewControllerDependency()) {
        self.dependencies = dependencies
        if let aDecoder = aDecoder {
            super.init(coder: aDecoder)
        }
        else {
            super.init()
        }
    }
    
//    required convenience init?(coder aDecoder: NSCoder) {
//        self.init(
//            coder: aDecoder,
//            dependencies: PinDetailViewControllerDependency()
//        )
//    }

    required init?(coder: NSCoder) {
        self.dependencies = PinDetailViewControllerDependency()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newCollectionButton.possibleTitles = [
            newCollectionButtonTitleDefault,
            newCollectionButtonTitleDownloading
        ]
        newCollectionButton.title = newCollectionButtonTitleDefault
        newCollectionButton.isEnabled = false
        
        do {
            try fetchedResultsController.performFetch()
        }
        catch let error as NSError {
            print("Error performining initial fetch: \(error)")
        }
        
        fetchedResultsController.delegate = self
        
        var numberOfPhotos = 0
        
        numberOfPhotos = self.annotation.pin.photos.count
        
        if numberOfPhotos == 0 {
            self.getPhotos()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let (state, remaining) = getPhotoDownloadStatus()
        enableNewCollectionButton(state, remaining: remaining)        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // invalidate layout to force relayout on rotation
        flowLayout.invalidateLayout()
    }
    
    
    // MARK: - Actions
    
    @IBAction func getNewCollection(_ sender: AnyObject) {
        newCollectionButton.isEnabled = false
        clearPhotos()
        getPhotos()
    }
    
    
    // MARK: - Helpers
    
    func getPhotoDownloadStatus() -> (completed: Bool, remaining: Int) {
        var numberOfPendingPhotos = 0
        
        for photo in self.fetchedResultsController.fetchedObjects!{
            if photo.imageData == nil {
                numberOfPendingPhotos += 1
            }
        }
        
        return (numberOfPendingPhotos == 0, numberOfPendingPhotos)
    }
    
    func getPhotos() {
        var lat: Double!
        var lon: Double!
        
        lat = self.annotation.pin.latitude
        lon = self.annotation.pin.longitude 
        
        let _ = flickrClient.searchByLocation(latitude: lat, longitude: lon) { (results, error) in
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
            
            let _ = self.flickrClient.searchByLocation(latitude: lat, longitude: lon, page: randomPage) { (results, error) in
                
                if let error = error {
                    print(error)
                    return
                }
                
                guard let photoResults = results![FlickrClient.ResponseKeys.Photos]?[FlickrClient.Photos.Photo] as? [[String:Any]] else {
                    print("Cannot find photo list in Photos object")
                    return
                }
                
                // check for actual existing photos
                // retry if page > 0 and photo array contains nothing
                
                self.coreDataStack.performBackgroundBatchOperation { (workerContext) in
                    let pin = workerContext.object(with: self.annotation.pin.objectID) as! Pin
                    
                    for record in photoResults {
                        let imageURLString = record[FlickrClient.Photo.MediumURL] as! String
                        let photo = Photo(imageURLString: imageURLString, context: workerContext)
                        photo.pin = pin
                    }
                }
                self.coreDataStack.saveMainContext()
            }
        }
    }
    
    func downloadAnImage() {
        coreDataStack.performBackgroundBatchOperation { (workerContext) in
            for photo in self.fetchedResultsController.fetchedObjects! {
                let photoInContext = try! workerContext.existingObject(with: photo.objectID) as! Photo
                if photoInContext.imageData == nil {
                    let _ = photoInContext.getImageData()
                    break
                }
            }
            self.coreDataStack.saveMainContext()
        }
    }
    
    func clearPhotos() {
        for object in self.fetchedResultsController.fetchedObjects! {
            self.coreDataStack.mainContext.delete(object)
        }
        coreDataStack.saveMainContext()
    }
    
    func enableNewCollectionButton(_ state: Bool, remaining count: Int = 0) {
        performUIUpdatesOnMain {
            if !state {
                self.newCollectionButton.title = "Downloading (\(count))"
            }
            else {
                self.newCollectionButton.title = self.newCollectionButtonTitleDefault
            }
            
            self.newCollectionButton.isEnabled = state
        }
    }
}


// MARK: - Collection View Data Source

extension PinDetailViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections!.count 
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        
        let sectionInfo = fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects + numberOfStaticCells
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cellIdentifier: String
        var cell: UICollectionViewCell
        
        if (indexPath as NSIndexPath).item == 0 {
            cellIdentifier = "Map"
            let mapCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! MapCollectionViewCell
            
            configureMapCell(mapCell, atIndexPath: indexPath)
            cell = mapCell
        }
        else {
            cellIdentifier = "PinPhoto"
            let pinPhotoCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PinPhotoCollectionViewCell

//            let indexPathAdjusted = IndexPath(item: (indexPath as NSIndexPath).item - numberOfStaticCells, section: 0)
            configurePinPhotoCell(pinPhotoCell, atIndexPath: indexPath, adjustedBy: 1)
            cell = pinPhotoCell
        }
        
        return cell
    }
    
    func configureMapCell(_ cell: MapCollectionViewCell, atIndexPath indexPath: IndexPath) {
        
        let lat = annotation.coordinate.latitude
        let lon = annotation.coordinate.longitude
        let radius = distanceInMeters(kilometers: Double(viewScaleRadiusKm))
        
        let coordinate = CLLocationCoordinate2DMake(lat, lon)
        let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: radius, longitudinalMeters: radius)
        
        cell.mapView.setRegion(region, animated: true)
        
        cell.mapView.removeAnnotations(cell.mapView.annotations)
        cell.mapView.addAnnotation(self.annotation)

    }
    
    func configurePinPhotoCell(_ cell: PinPhotoCollectionViewCell, atIndexPath indexPath: IndexPath, adjustedBy adjustment: Int) {

        let indexPathAdjusted = IndexPath(item: (indexPath as NSIndexPath).item - adjustment, section: 0)

        let photo = fetchedResultsController.object(at: indexPathAdjusted)
        var imageData: Data!
        
        imageData = photo.imageData
        
        cell.showLoading()
        guard (imageData != nil) else {
            coreDataStack.performBackgroundBatchOperation { (workerContext) in
                let photoInContext = workerContext.object(with: photo.objectID) as! Photo
                let pendingImageData = photoInContext.getImageData()
                // use normal indexPath for cell selection
                performUIUpdatesOnMain {
                    if let cellToUpdate = self.collectionView.cellForItem(at: indexPath) as? PinPhotoCollectionViewCell {
                        cellToUpdate.showImage(pendingImageData)
                    }
                }
                self.coreDataStack.saveMainContext()
            }
            
            return
        }
        
        cell.showImage(imageData)
    }
}


// MARK: - Collection View Delegate

extension PinDetailViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (indexPath as NSIndexPath).item != 0 else {
            return
        }
        
        guard getPhotoDownloadStatus().completed else {
            return
        }
        
        
        let indexPathAdjusted = IndexPath(item: (indexPath as NSIndexPath).item - numberOfStaticCells, section: 0)


        coreDataStack.performBackgroundBatchOperation { (workerContext) in
            let photo = self.fetchedResultsController.object(at: indexPathAdjusted) 
            let photoInContext = workerContext.object(with: photo.objectID)
            workerContext.delete(photoInContext)
        }
        
        coreDataStack.saveMainContext()
    }
}


// MARK: - Fetched Results Controller Delegate

extension PinDetailViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
        ) {
        
    
        switch type {
        case .insert:
            let newIndexPathAdjusted = IndexPath(item: (newIndexPath! as NSIndexPath).item + numberOfStaticCells, section: 0)
            insertedIndexPaths.append(newIndexPathAdjusted)
        case .delete:
            let indexPathAdjusted = IndexPath(item: (indexPath! as NSIndexPath).item + numberOfStaticCells, section: 0)
            deletedIndexPaths.append(indexPathAdjusted)
        case .update:
            let indexPathAdjusted = IndexPath(item: (indexPath! as NSIndexPath).item + numberOfStaticCells, section: 0)
            updatedIndexPaths.append(indexPathAdjusted)
        case .move:
            fallthrough
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        self.collectionView.performBatchUpdates(
            { () -> Void in
                
                for indexPath in self.insertedIndexPaths {
                    self.collectionView.insertItems(at: [indexPath])
                }
                
                for indexPath in self.deletedIndexPaths {
                    self.collectionView.deleteItems(at: [indexPath])
                }
                
                for indexPath in self.updatedIndexPaths {
                    self.collectionView.reloadItems(at: [indexPath])
                }
            },
            completion: { (success) in
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = floor(collectionView.frame.size.width)
        let height = floor(collectionView.frame.size.height)
        
        let numberAcross:CGFloat = ((width < height) ? 3.0 : 5.0)
        
        let itemSize = (width - ((numberAcross - 1) * flowLayout.minimumLineSpacing)) / numberAcross
        
        return CGSize(width: itemSize, height: itemSize)
    }
}
