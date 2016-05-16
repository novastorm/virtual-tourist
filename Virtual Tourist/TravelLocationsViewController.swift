//
//  TravelLocationsViewController.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/11/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import UIKit
import MapKit


class TravelLocationsViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
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
        
        mapView.setRegion(region, animated: true)
        mapView.delegate = self
    }
    
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        print("\(#function)")
        guard sender.state == .Began else {
            return
        }
        
        dropPin(at: sender.locationInView(mapView))
    }
    
    func dropPin(at touchPoint: CGPoint) {
        print("\(#function)")
        
        let mapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapCoordinate
        
        mapView.addAnnotation(annotation)
    }
}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).saveMapViewRegion(mapView.region)
    }
}