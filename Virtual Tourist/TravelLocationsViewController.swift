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
        return CoreDataStackManager.shared.mainContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Pin> = {
        let fetchRequest  = Pin.fetchRequest() as! NSFetchRequest<Pin>
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController<Pin>(fetchRequest: fetchRequest, managedObjectContext: self.sharedMainContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    func saveContext() {
        CoreDataStackManager.shared.saveMainContext()
    }
    
    func saveTempContext(_ context: NSManagedObjectContext) {
        CoreDataStackManager.shared.saveTemporaryContext(context)
    }
    
    // MARK: - View Cycle
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let savedRegion = UserDefaults.standard.object(forKey: AppDelegate.UserDefaultKeys.MapViewRegion) as! [String: Any]
        
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
        mapView.setCenter(region.center, animated: true)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
        
        super.viewWillDisappear(animated)
    }

    
    // MARK: - Actions
    
    @IBAction func handleLongPress(_ sender: UILongPressGestureRecognizer) {

        switch sender.state {
        case .began:
            addPin(at: sender.location(in: mapView))
            // refactor to setup pin and draggable
            break
        case .changed:
            // have pin track user touch location
            break
        case .ended:
            // drop pin at last touchpoint
            break
        default:
            break
        }
    }
    
    
    // MARK: - Helpers
    
    func updateMapAnnotations() {
        let pins = fetchedResultsController.fetchedObjects!
        var annotations = [MKAnnotation]()
        
        for pin in pins {
            let annotation = PinAnnotation(withPin: pin)
            
            annotations.append(annotation)
        }
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotations(annotations)
    }
    
    func addPin(at touchPoint: CGPoint) {
        
        let mapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let pin = Pin(lat: mapCoordinate.latitude, lon: mapCoordinate.longitude, context: self.sharedMainContext)
        
        saveContext()
        
        let annotation = PinAnnotation(withPin: pin)
        mapView.addAnnotation(annotation)
    }
    
    func saveMapViewRegion(_ region: MKCoordinateRegion) {
        UserDefaults.standard.set([
                  "latitude": region.center.latitude,
                 "longitude": region.center.longitude,
             "latitudeDelta": region.span.latitudeDelta,
            "longitudeDelta": region.span.longitudeDelta
            ], forKey: AppDelegate.UserDefaultKeys.MapViewRegion)
    }
}


// MARK: - MKMapViewDelegate extentions

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView
        
        if #available(iOS 11.0, *) {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        }
        
        annotationView.isDraggable = true
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapViewRegion(mapView.region)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // deselect annotation to free selection when returning to this view
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        let pinDetailVC = storyboard?.instantiateViewController(withIdentifier: "PinDetailViewController") as! PinDetailViewController
        
        pinDetailVC.annotation = view.annotation as! PinAnnotation
  
        navigationController!.pushViewController(pinDetailVC, animated: true)
//        presentingViewController?.performSegue(withIdentifier: "ShowPinDetail", sender: self)
    }
    
}

extension TravelLocationsViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateMapAnnotations()
    }
}
