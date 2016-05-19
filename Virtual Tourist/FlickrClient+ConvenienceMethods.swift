//
//  FlickrClient+ConvenienceMethods.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/18/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    func searchByLocation(latitude lat: Double, longitude lon: Double, completion: (results: AnyObject?, error: NSError?) -> Void) {
        
        // resign all first responder
        // disable UI
        
        let minLon = max(lon - Config.SearchBBoxHalfWidth, Config.SearchLonRange.0)
        let minLat = max(lat - Config.SearchBBoxHalfHeight, Config.SearchLatRange.0)
        let maxLon = min(lon + Config.SearchBBoxHalfWidth, Config.SearchLonRange.1)
        let maxLat = min(lat + Config.SearchBBoxHalfHeight, Config.SearchLatRange.1)
        let boundingBoxString = "\(minLon),\(minLat),\(maxLon),\(maxLat)"

        
        let parameters: [String: String] = [
            ParameterKeys.APIKey: ParameterValues.APIKey,
            ParameterKeys.BoundingBox: boundingBoxString,
            ParameterKeys.Extras: ParameterValues.MediumURL,
            ParameterKeys.Format: ParameterValues.ResponseFormat,
            ParameterKeys.Method: Methods.Photos.Search,
            ParameterKeys.NoJSONCallback: ParameterValues.DisableJSONCallback,
            ParameterKeys.SafeSearch: ParameterValues.UseSafeSearch,
        ]
        
        taskForGetMethod("/", parameters: parameters) { (results, error) in
            print("\(#function)")
            completion(results: results, error: error)
        }
        
        // enable UI
    }
}