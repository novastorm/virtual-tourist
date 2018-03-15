//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/11/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import CoreData
import MapKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    struct UserDefaultKeys {
        static let HasLaunchedBefore = "hasLaunchedBefore"
        static let MapViewRegion = "mapViewRegion"
    }
    
    var window: UIWindow?

    let coreDataStack: CoreDataStack = CoreDataStack_v1(modelName: "Virtual_Tourist")!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {        
        checkIfFirstLaunch()
        coreDataStack.autoSave(60)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        coreDataStack.saveMainContext()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        coreDataStack.saveMainContext()
    }

    // MARK: - Helpers
    
    func checkIfFirstLaunch() {
        if !UserDefaults.standard.bool(forKey: UserDefaultKeys.HasLaunchedBefore) {
            UserDefaults.standard.set(true, forKey: UserDefaultKeys.HasLaunchedBefore)
            
            let lat = 37.3997925
            let lon = -122.1099743
            let radius = 5000.0
            
            let coordinate = CLLocationCoordinate2DMake(lat, lon)
            let region = MKCoordinateRegionMakeWithDistance(coordinate, radius, radius)

            // Set default to Udacity HQ
            UserDefaults.standard.set([
                "latitude": region.center.latitude,
                "longitude": region.center.longitude,
                "latitudeDelta": region.span.latitudeDelta,
                "longitudeDelta": region.span.longitudeDelta
                ], forKey: UserDefaultKeys.MapViewRegion)
            return
        }
    }
}

