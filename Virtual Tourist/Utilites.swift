//
//  Utilites.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/12/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import Foundation

/**
 Random number generator between upper and lower numbers inclusive.
 
 - Parameters:
    - upper: Upper value
    - lower: Lower value. Default is 0
 */

func random(_ upper: Int, start lower: Int = 0) -> Int {
    return Int(arc4random_uniform(UInt32(upper - lower + 1))) + lower
}

/**
 Convert to distance in meters
 
 - Parameters:
     - kilometers: value in kilometers
 */

func distanceInMeters(kilometers: Double) -> Double {
    return kilometers * 1000
}
