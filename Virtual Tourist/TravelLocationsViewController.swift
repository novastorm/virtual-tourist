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
    
}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).saveMapViewRegion(mapView.region)
    }
}