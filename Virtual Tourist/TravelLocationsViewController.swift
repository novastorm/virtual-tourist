//
//  TravelLocationsViewController.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/11/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import CoreData
import MapKit
import UIKit


class TravelLocationsViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    
    // MARK: - Core Data convenience methods
    
    var sharedMainContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.mainContext
    }
    
    var sharedBackgroundContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.backgroundContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedBackgroundContext, sectionNameKeyPath: nil, cacheName: nil)
        
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
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let savedRegion = NSUserDefaults.standardUserDefaults().objectForKey(AppDelegate.UserDefaultKeys.MapViewRegion) as! [String: AnyObject]
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2DMake(
                savedRegion["latitude"] as! Double,
                savedRegion["longitude"] as! Double
                ),
            span: MKCoordinateSpan(
                 latitudeDelta: savedRegion["latitudeDelta"] as! Double,
                longitudeDelta: savedRegion["longitudeDelta"] as! Double
                )
            )
        
        mapView.setRegion(region, animated: false)
        mapView.setCenterCoordinate(region.center, animated: true)
        mapView.delegate = self
        
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            abort()
        }
        
        updateMapAnnotations()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.navigationBarHidden = false
        
        super.viewWillDisappear(animated)
    }

    
    // MARK: - Actions
    
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {

        switch sender.state {
        case .Began:
            addPin(at: sender.locationInView(mapView))
            // refactor to setup pin and draggable
            break
        case .Changed:
            // have pin track user touch location
            break
        case .Ended:
            // drop pin at last touchpoint
            break
        default:
            break
        }
    }
    
    
    // MARK: - Helpers
    
    func updateMapAnnotations() {
        var pins = [Pin]()
        sharedBackgroundContext.performBlockAndWait {
            pins = self.fetchedResultsController.fetchedObjects as! [Pin]
        }
        var annotations = [MKAnnotation]()
        
        for pin in pins {
            let annotation = PinAnnotation(withPin: pin)
            
            annotations.append(annotation)
        }
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotations(annotations)
    }
    
    func addPin(at touchPoint: CGPoint) {
        
        let mapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: self.sharedBackgroundContext)!
        var pin: Pin!
            
        CoreDataStackManager.sharedInstance.performBackgroundBatchOperation { (workerContext) in
            pin = Pin(entity: entity, insertIntoManagedObjectContext: workerContext)
            pin.latitude = mapCoordinate.latitude
            pin.longitude = mapCoordinate.longitude
        }
        
        saveContext()
        
        let annotation = PinAnnotation(withPin: pin)
        mapView.addAnnotation(annotation)
    }
    
    func saveMapViewRegion(region: MKCoordinateRegion) {
        NSUserDefaults.standardUserDefaults().setObject([
                  "latitude": region.center.latitude,
                 "longitude": region.center.longitude,
             "latitudeDelta": region.span.latitudeDelta,
            "longitudeDelta": region.span.longitudeDelta
            ], forKey: AppDelegate.UserDefaultKeys.MapViewRegion)
    }
}


// MARK: - MKMapViewDelegate extentions

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapViewRegion(mapView.region)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        let pinDetailVC = storyboard?.instantiateViewControllerWithIdentifier("PinDetailViewController") as! PinDetailViewController
        
        pinDetailVC.annotation = view.annotation as! PinAnnotation
        
        navigationController!.pushViewController(pinDetailVC, animated: true)
    }
    
}

extension TravelLocationsViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        updateMapAnnotations()
    }
}
