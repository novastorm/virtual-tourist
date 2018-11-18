//
//  CoreDataStackDependency.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 4/1/18.
//  Copyright © 2018 Adland Lee. All rights reserved.
//

import CoreData
import UIKit

protocol CoreDataStackDependency {
    var coreDataStack: CoreDataStack { get }
}
