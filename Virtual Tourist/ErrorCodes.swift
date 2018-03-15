//
//  ErrorCodes.swift
//  On the Map
//
//  Created by Adland Lee on 3/30/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import Foundation

enum ErrorCodes: Int, CustomStringConvertible {
    case genericError
    case networkError
    case genericRequestError
    case httpUnsucessful
    case noData
    case dataError
    
    var description: String {
        get {
            switch self {
            case .genericError:
                return "Generic Error"
            case .networkError:
                return "Network Error"
            case .genericRequestError:
                return "There was an error with the request."
            case .httpUnsucessful:
                return "Request returned a status code other that 2XX!"
            case .noData:
                return "No data returned by the request"
            case .dataError:
                return "There was a data error"
            }
        }
    }
}
