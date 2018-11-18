//
//  Virtual_TouristTests.swift
//  Virtual TouristTests
//
//  Created by Adland Lee on 3/25/18.
//  Copyright © 2018 Adland Lee. All rights reserved.
//

import XCTest
import CoreData

@testable import Virtual_Tourist

class Virtual_TouristTests: XCTestCase {
    
    var persistentContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        persistentContainer = NSPersistentContainer(name: "Virtual_Tourist")
        
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
        
        persistentContainer.persistentStoreDescriptions = [persistentStoreDescription]
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

    func testPin() {
        let pin = Pin(lat: 37.3998683, lon: -122.1105829, context: persistentContainer.viewContext)
        print(pin)
    }
}
