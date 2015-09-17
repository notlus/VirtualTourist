//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/14/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import Foundation

protocol FlickrDataHandler {
    func handleData(data: NSData)
}

public class FlickrClient {
    
    struct Flickr {
        static let API_KEY = "7a7950524c71e50ecca5e2bd7535fe69"
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let API_METHOD = "flickr.photos.search"
        static let FORMAT = "json"
        static let EXTRAS = "url_m"
    }

    private let session = NSURLSession.sharedSession()

    private let MIN_LATITUDE    = -90.0
    private let MAX_LATITUDE    =  90.0
    private let MIN_LONGITUDE   = -180.0
    private let MAX_LONGITUDE   =  180.0
    
    var dataHandler: FlickrDataHandler!
    
//    init(dataHandler: FlickrDataHandler) {
//        self.dataHandler = dataHandler
//    }
    
    /// Given a latitude and longitude, attempt to download images from Flickr. Call the provided
    /// completion handler when done.
    func downloadImagesForLocation(latitude: Double, longitude: Double, storagePath: NSURL, completion: (error: NSError?) -> ()) {
        if latitude < MIN_LATITUDE || latitude > MAX_LATITUDE || longitude < MIN_LONGITUDE || longitude > MAX_LONGITUDE {
            print("Invalid latitude/longitude")
            let error = NSError(domain: "Invalid latitude/longitude", code: 100, userInfo: nil)
            completion(error: error)
        }
        
        let boundingBox = createBoundingBox("\(latitude)", "\(longitude)")
        print("Bounding box=\(boundingBox)")
        
        let methodArguments = [
            "method": Flickr.API_METHOD,
            "api_key": Flickr.API_KEY,
            "format": Flickr.FORMAT,
            "extras": Flickr.EXTRAS,
            "bbox": boundingBox,
            "nojsoncallback": "1"
        ]

        getImageFromFlickr(methodArguments) { (photosData, error) -> () in
            if let error = error {
                print("Received an error downloading photos: \(error)")
            } else {
                print("Got \(photosData.count) photos")
                
                // Save the photos at the paths to `storagePath`
                _ = photosData.map({(photoData: [String: AnyObject]) -> NSURL in
                    if let photoURL = photoData["url_m"] as? String {
                        if let data = NSData(contentsOfURL: NSURL(string: photoURL)!) {
                            let title = photoData["title"] as! String
                            let filename = "\(title)-\(NSDate().timeIntervalSince1970)"
                            if let fullPath = NSURL(string: filename, relativeToURL: storagePath) {
                                if (!data.writeToURL(fullPath, atomically: false)) {
                                    print("Failed to write to URL: \(fullPath)")
                                }
                            return NSURL(fileURLWithPath: fullPath.path!)
                            }
                        }
                    }
                    return NSURL()
                })
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
                    print("status: \(httpResponse.statusCode)\nall headers: \(httpResponse.allHeaderFields)")
//                    var jsonError: NSError? = nil
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
                        // Now we have an array of photo information. We want to retrieve the
                        // photo data from the URL (`url_m`) for each photo
//                        let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
//                        if let photoURL = photoArray[randomIndex]["url_m"] as? String {
//                            println("Got URL \(photoURL) for photo at index \(randomIndex)")
                        
                            // Get the photo
//                            if let photoData = NSData(contentsOfURL: NSURL(string: photoURL)!) {
//                                self.dataHandler.handleData(photoData)
//                                let image = UIImage(data: photoData)
//                                let title = photoArray[randomIndex]["title"] as! String
//                            }
//                        }
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
//            methodString += (methodString.isEmpty ? "?" : "&") + key + "=" + value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
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
