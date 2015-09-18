//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/14/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import Foundation

public class FlickrClient {
    
    struct Flickr {
        static let API_KEY = "7a7950524c71e50ecca5e2bd7535fe69"
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let API_METHOD = "flickr.photos.search"
        static let FORMAT = "json"
        static let EXTRAS = "url_m"
        static let MAX_PAGE = "20"
    }

    private let session = NSURLSession.sharedSession()

    private let MIN_LATITUDE    = -90.0
    private let MAX_LATITUDE    =  90.0
    private let MIN_LONGITUDE   = -180.0
    private let MAX_LONGITUDE   =  180.0
    
    static let sharedInstance = FlickrClient()
    
    /// Given a latitude and longitude, attempt to download images from Flickr. Call the provided
    /// completion handler when done.
    func downloadImagesForLocation(latitude: Double, longitude: Double, storagePath: NSURL, completion: (photos: [NSURL]?, error: NSError?) -> ()) {
        if latitude < MIN_LATITUDE || latitude > MAX_LATITUDE || longitude < MIN_LONGITUDE || longitude > MAX_LONGITUDE {
            print("Invalid latitude/longitude")
            let error = NSError(domain: "Invalid latitude/longitude", code: 100, userInfo: nil)
            completion(photos: nil, error: error)
        }
        
        let boundingBox = createBoundingBox("\(latitude)", "\(longitude)")
        print("Bounding box=\(boundingBox)")
        
        let methodArguments = [
            "method": Flickr.API_METHOD,
            "api_key": Flickr.API_KEY,
            "format": Flickr.FORMAT,
            "extras": Flickr.EXTRAS,
            "per_page": Flickr.MAX_PAGE,
            "bbox": boundingBox,
            "nojsoncallback": "1"
        ]

        getImageFromFlickr(methodArguments) { (photosData, error) -> () in
            if let error = error {
                print("Received an error downloading photos: \(error)")
            } else {
                print("Got \(photosData.count) photos")
                
                // Save the photos at the paths to `storagePath` and return an array of the paths
                let photos = photosData.map({(photoData: [String: AnyObject]) -> NSURL in
                    if let photoURL = photoData["url_m"] as? String,
                       let data = NSData(contentsOfURL: NSURL(string: photoURL)!) {
                        
                        let title = photoData["title"] as! String
                        let filename = "\(NSDate().timeIntervalSince1970)-\(title)"
                        if let fullPath = NSURL(string: filename, relativeToURL: storagePath) {
                            if (!data.writeToURL(fullPath, atomically: false)) {
                                print("Failed to write to URL: \(fullPath)")
                            }
                            
                            return NSURL(fileURLWithPath: fullPath.path!)
                        }
                    }
                    
                    return NSURL()
                })
                
                print("Photos: \(photos)")
                completion(photos: photos, error: nil)
            }
        }
    }
    
    private func getImageFromFlickr(arguments: [String: String], completion: (photoPaths: [[String: AnyObject]], error: NSError?) -> ()) {
        
        // Create a URL from the arguments
        if let flickrURL = createURLFromArguments(arguments) {
            let request = NSURLRequest(URL: flickrURL)
            let task = session.dataTaskWithRequest(request) { data, response, error in
                if let err = error {
                    print("Request failed with error=\(err)")
                }
                else {
                    print("Request succeeded")
                    let httpResponse = response as! NSHTTPURLResponse
                    print("status: \(httpResponse.statusCode)")
                    let parsedResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as! [String: AnyObject]
                    print(parsedResult)
                    
                    // Get the `photos` dictionary from the parsed response
                    let photos = parsedResult["photos"] as! [String: AnyObject]
                    
                    // See if we got any results
                    let total = Int((photos["total"] as! String))!
                    if total > 0 {
                        print("Received \(total) photos!")
                        
                        let photoArray = photos["photo"] as! [[String: AnyObject]]
                        completion(photoPaths: photoArray, error: nil)
                    }
                    else {
                        completion(photoPaths: [[String: AnyObject]](), error: NSError(domain: "FlickrClient", code: -1, userInfo: nil))
                    }
                }
            }
            
            task.resume()
        }
        else
        {
            print("Failed to create Flickr URL")
        }
    }
    
    private func createURLFromArguments(arguments: [String: String]) -> NSURL? {
        var methodString = String()
        for (key, value) in arguments {
            methodString += (methodString.isEmpty ? "?" : "&") + key + "=" + value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLUserAllowedCharacterSet())!
        }
        
        let urlString = Flickr.BASE_URL + methodString
        
        if let components = NSURLComponents(string: urlString) {
            print("Got components")
            return components.URL
        }
        
        return nil
    }

    private func createBoundingBox(lat: String, _ lon: String) -> String {
        return "\(lon),\(lat),\(lon),\(lat)"
    }

}
