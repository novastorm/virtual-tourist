//
//  FlickrClient+ConvenienceMethods.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/18/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    func searchByLocation(latitude lat: Double, longitude lon: Double, page: Int = 1, completion: @escaping (_ results: [String:AnyObject]?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        // resign all first responder
        // disable UI
        
        let minLon = max(lon - Config.SearchBBoxHalfWidth, Config.SearchLonRange.0)
        let minLat = max(lat - Config.SearchBBoxHalfHeight, Config.SearchLatRange.0)
        let maxLon = min(lon + Config.SearchBBoxHalfWidth, Config.SearchLonRange.1)
        let maxLat = min(lat + Config.SearchBBoxHalfHeight, Config.SearchLatRange.1)
        let boundingBoxString = "\(minLon),\(minLat),\(maxLon),\(maxLat)"

        
        let parameters: [String: Any] = [
            ParameterKeys.APIKey: ParameterValues.APIKey as AnyObject,
            ParameterKeys.BoundingBox: boundingBoxString as AnyObject,
            ParameterKeys.Extras: ParameterValues.MediumURL as AnyObject,
            ParameterKeys.Format: ParameterValues.ResponseFormat as AnyObject,
            ParameterKeys.HasGeo: ParameterValues.IsGeoTagged as AnyObject,
            ParameterKeys.Method: Methods.Photos.Search as AnyObject,
            ParameterKeys.NoJSONCallback: ParameterValues.DisableJSONCallback as AnyObject,
            ParameterKeys.SafeSearch: ParameterValues.UseSafeSearch,
            ParameterKeys.PerPage: ParameterValues.PerPage,
            ParameterKeys.Page: page,
            ParameterKeys.Radius: Config.SearchRadius
        ]
        
        let task = taskForGetMethod("/", parameters: parameters) { (results, error) in

            // Custom error function
            func sendError(_ code: Int, errorString: String) {
                var userInfo = [String: Any]()
                
                userInfo[NSLocalizedDescriptionKey] = errorString
                userInfo[NSUnderlyingErrorKey] = error
                userInfo["results"] = results
                
                completion(nil, NSError(domain: "searchByLocation", code: code, userInfo: userInfo))
            }
            
            if let error = error {
                sendError(error.code, errorString: error.localizedDescription)
                return
            }
            
            let results = results as! [String: AnyObject]
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = results[ResponseKeys.Status] as? String, stat == ResponseValues.OKStatus else {
                sendError(1, errorString: "Flickr API returned an error. See error code")
                return
            }
            
            completion(results, nil)
        }
        
        // enable UI
        
        return task
    }
    
}
