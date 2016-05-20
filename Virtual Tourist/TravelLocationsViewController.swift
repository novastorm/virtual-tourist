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
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
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

    
    // MARK: - Actions
    
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        print("\(#function)")
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
        let pins = fetchedResultsController.fetchedObjects as! [Pin]
        var annotations = [MKAnnotation]()
        
        for pin in pins {
            let lat = pin.latitude as! Double
            let lon = pin.longitude as! Double
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            
            annotations.append(annotation)
        }
        
        performUIUpdatesOnMain {
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotations(annotations)
        }
    }
    
    func addPin(at touchPoint: CGPoint) {
        
        let mapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapCoordinate
        
        let _ = Pin(
            lat: mapCoordinate.latitude,
            lon: mapCoordinate.longitude,
            context: sharedContext)
        
        saveContext()
        
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
        
        let PinDetailVC = storyboard?.instantiateViewControllerWithIdentifier("PinDetailViewController") as! PinDetailViewController
        
        PinDetailVC.annotation = view.annotation
        
        presentViewController(PinDetailVC, animated: true, completion: nil)
    }
    
}

extension TravelLocationsViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        updateMapAnnotations()
    }
}
