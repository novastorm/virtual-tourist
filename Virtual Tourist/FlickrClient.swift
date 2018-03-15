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
    fileprivate init() {}
    
    
    // MARK: - Properties
    
    var session = URLSession.shared
    
    
    // MARK: HTTP Methods
    
    func taskForGetMethod(_ resource: String, parameters: [String: Any], completionHandler: @escaping (_ results: Any?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        // Set Parameters
//        var parameters = parameters
        
        // Build URL and configure request
        let request = NSMutableURLRequest(url: URLFromParameters(parameters, withPathExtension: resource))
        
        // Make request
        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            // Custom error function
            func sendError(_ code: Int, errorString: String) {
                var userInfo = [String: Any]()
                
                userInfo[NSLocalizedDescriptionKey] = errorString
                userInfo[NSUnderlyingErrorKey] = error
                userInfo["http_response"] = response
                
                completionHandler(nil, NSError(domain: "taskForGetMethod", code: code, userInfo: userInfo))
            }

            if let error = error {
                sendError(error._code, errorString: error.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , 200 ... 299 ~= statusCode else {
                sendError(ErrorCodes.httpUnsucessful.rawValue, errorString: ErrorCodes.httpUnsucessful.description)
                return
            }
            
            self.convertDataWithCompletionHandler(data!, completionHandlerForConvertData: completionHandler)
        }) 
        
        task.resume()
        
        return task
    }
    
    
    // MARK: - Helpers
    
    // substitute the key for the value that is contained within the method name
    func subtituteKeyInMethod(_ method: String, key: String, value: String) -> String? {
        if method.range(of: "{\(key)}") != nil {
            return method.replacingOccurrences(of: "{\(key)}", with: value)
        } else {
            return nil
        }
    }
    
    // given a Dictionary, return a JSON String
    fileprivate func convertObjectToJSONData(_ object: AnyObject) -> Data{
        
        var parsedResult: Any!
        do {
            parsedResult = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: 0))
        }
        catch {
            return Data()
        }
        
        return parsedResult as! Data
    }
    
    // given raw JSON, return a usable Foundation object
    fileprivate func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: Any?, _ error: NSError?) -> Void) {
        
        var parsedResult: Any?
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    // create a URL from parameters
    fileprivate func URLFromParameters(_ parameters: [String:Any], withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = API.Scheme
        components.host = API.Host
        components.path = API.Path + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }

}
