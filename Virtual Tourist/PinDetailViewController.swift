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
    
    var annotation: PinAnnotation!
    
    
    // MARK: - Core Data convenience methods
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.annotation.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
    
    // MARK: - View Cycle
    
    override func prefersStatusBarHidden() -> Bool {
        return true
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
        }
        
        if annotation.pin.photos?.count == 0 {
            getPhotos()
        }
    }

    // MARK: - Actions
    
    @IBAction func doneViewing(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Helpers
    
    func getPhotos() {
        let lat = annotation.coordinate.latitude
        let lon = annotation.coordinate.longitude

        FlickrClient.sharedInstance.searchByLocation(latitude: lat, longitude: lon) { (results, error) in
            print("\(#function)")
            if let error = error {
                print(error)
                return
            }
            
            let data = results![FlickrClient.ResponseKeys.Photos] as! [String: AnyObject]
            let pages = data[FlickrClient.Photos.Pages] as! Int
            let randomPage = random(pages, start: 1)
            
            FlickrClient.sharedInstance.searchByLocation(latitude: lat, longitude: lon, page: randomPage) { (results, error) in
                print(results)
            }
        }
        
    }
}