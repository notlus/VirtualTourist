//
//  FlickrClientTests.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/14/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import UIKit
import XCTest

class FlickrClientTests: XCTestCase {

    private var flickrClient = FlickrClient()
    private lazy var documentsDirectory: NSURL = {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    }()
    
    private lazy var photosPath: NSURL = {
       self.documentsDirectory.URLByAppendingPathComponent("VirtualTouristPhotos")
    }()

    func handleData(data: NSData) {
        print("handleData")
    }
    
    override func setUp() {
        super.setUp()
//        flickrClient.dataHandler = self
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFlickrDownloadInvalidLatitude() {
        flickrClient.downloadImagesForLocation(-1000, longitude: 0, storagePath: photosPath) { (photos, error) -> () in
            let result = error != nil
            XCTAssert(result, "downloadImagesForLocation failed")
        }

        flickrClient.downloadImagesForLocation(1000, longitude: 0, storagePath: photosPath) { (photos, error) -> () in
            let result = error != nil
            XCTAssert(result, "downloadImagesForLocation failed")
        }

        flickrClient.downloadImagesForLocation(-91, longitude: 0, storagePath: photosPath) { (photos, error) -> () in
            let result = error != nil
            XCTAssert(result, "downloadImagesForLocation failed")
        }

        flickrClient.downloadImagesForLocation(91, longitude: 0, storagePath: photosPath) { (photos, error) -> () in
            let result = error != nil
            XCTAssert(result, "downloadImagesForLocation failed")
        }
}

    func testFlickrDownloadInvalidLongitude() {
        flickrClient.downloadImagesForLocation(0, longitude: -1000, storagePath: photosPath) { (photos, error) -> () in
            let result = error != nil
            XCTAssert(result, "downloadImagesForLocation failed")
        }

        flickrClient.downloadImagesForLocation(0, longitude: 1000, storagePath: photosPath) { (photos, error) -> () in
            let result = error != nil
            XCTAssert(result, "downloadImagesForLocation failed")
        }
        
        flickrClient.downloadImagesForLocation(0, longitude: -181, storagePath: photosPath) { (photos, error) -> () in
            let result = error != nil
            XCTAssert(result, "downloadImagesForLocation failed")
        }
        
        flickrClient.downloadImagesForLocation(0, longitude: 181, storagePath: photosPath) { (photos, error) -> () in
            let result = error != nil
            XCTAssert(result, "downloadImagesForLocation failed")
        }

    }

    func testFlickrDownloadValid() {
        let lat = 34.0500
        let lon = 118.25
        
        flickrClient.downloadImagesForLocation(lat, longitude: lon, storagePath: photosPath) { (photos, error) -> () in
            print("Got some imaages")
        }
    }

}
