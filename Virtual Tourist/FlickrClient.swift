//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/18/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import Foundation

class FlickrClient {
    
    // MARK: Shared Instance
    
    static let sharedInstance = FlickrClient()
    private init() {}
    
    
    // MARK: - Properties
    
    var session = NSURLSession.sharedSession()
    
    
    // MARK: HTTP Methods
    
    func taskForGetMethod(resource: String, parameters: [String: AnyObject], completionHandler: (results: AnyObject?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        // Set Parameters
//        var parameters = parameters
        
        // Build URL and configure request
        let request = NSMutableURLRequest(URL: URLFromParameters(parameters, withPathExtension: resource))
        
        // Make request
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            // Custom error function
            func sendError(code: Int, errorString: String) {
                var userInfo = [String: AnyObject]()
                
                userInfo[NSLocalizedDescriptionKey] = errorString
                userInfo[NSUnderlyingErrorKey] = error
                userInfo["http_response"] = response
                
                completionHandler(results: nil, error: NSError(domain: "taskForGetMethod", code: code, userInfo: userInfo))
            }

            if let error = error {
                sendError(error.code, errorString: error.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where 200 ... 299 ~= statusCode else {
                sendError(ErrorCodes.HTTPUnsucessful.rawValue, errorString: ErrorCodes.HTTPUnsucessful.description)
                return
            }
            
            self.convertDataWithCompletionHandler(data!, completionHandlerForConvertData: completionHandler)
        }
        
        task.resume()
        
        return task
    }
    
    
    // MARK: - Helpers
    
    // substitute the key for the value that is contained within the method name
    func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    // given a Dictionary, return a JSON String
    private func convertObjectToJSONData(object: AnyObject) -> NSData{
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions(rawValue: 0))
        }
        catch {
            return NSData()
        }
        
        return parsedResult as! NSData
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }
    
    // create a URL from parameters
    private func URLFromParameters(parameters: [String:AnyObject], withPathExtension: String? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = API.Scheme
        components.host = API.Host
        components.path = API.Path + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }

}