//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/14/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import Foundation

public class FlickrClient {
    
    struct APIConstants {
        static let API_KEY = "7a7950524c71e50ecca5e2bd7535fe69"
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let API_METHOD = "flickr.photos.search"
        static let FORMAT = "json"
        static let EXTRAS = "url_m"
        static let MAX_PAGE = "21"
    }

    private let session = NSURLSession.sharedSession()

    private let MIN_LATITUDE    = -90.0
    private let MAX_LATITUDE    =  90.0
    private let MIN_LONGITUDE   = -180.0
    private let MAX_LONGITUDE   =  180.0
    
    static let sharedInstance = FlickrClient()
    
    /// Given a latitude and longitude, attempt to download images from Flickr. Call the provided
    /// completion handler when done.
    func downloadImagesForLocation(pin: Pin, pageCount: Int, storagePath: NSURL, completion: (photos: [Photo]?, pageCount: Int, error: NSError?) -> ()) {
        if pin.latitude < MIN_LATITUDE || pin.latitude > MAX_LATITUDE || pin.longitude < MIN_LONGITUDE || pin.longitude > MAX_LONGITUDE {
            print("Invalid latitude/longitude")
            let error = NSError(domain: "Invalid latitude/longitude", code: 100, userInfo: nil)
            completion(photos: nil, pageCount: pageCount, error: error)
        }
        
        let boundingBox = createBoundingBox(pin.latitude, pin.longitude)
        print("Bounding box=\(boundingBox)")
        
        let randomPage = "\(arc4random_uniform(UInt32(pin.pageCount) + 1) % 192)"
        let methodArguments = [
            "method": APIConstants.API_METHOD,
            "api_key": APIConstants.API_KEY,
            "format": APIConstants.FORMAT,
            "extras": APIConstants.EXTRAS,
            "per_page": APIConstants.MAX_PAGE,
            "bbox": boundingBox,
            "nojsoncallback": "1",
            "page": randomPage
        ]
        
        print("*** Using page count \(pin.pageCount) and got random page \(randomPage)")
        
        getImageFromFlickr(methodArguments) { (photosData, pageCount, error) -> () in
            if let error = error {
                print("Received an error downloading photos: \(error)")
            } else {
                print("Got \(photosData.count) photos")
                
                // Save the photos at the paths to `storagePath` and return an array of remote URL
                // file path tuples
                let photos = photosData.map({(photoData: [String: AnyObject]) -> (NSURL, NSURL) in

                    if let photoURL = NSURL(string: (photoData["url_m"] as? String)!) {
                        // Create the filename and write to storage
                        let filename = "\(NSDate().timeIntervalSince1970)-\(arc4random())"
                        if let fullPath = NSURL(string: filename, relativeToURL: storagePath) {
                            return (photoURL, fullPath)
                        } else {
                            print("Failed to create url for fullpath: \(filename) and \(storagePath)")
                        }
                    }

                    return (NSURL(), NSURL())
                })

                var newPhotos = [Photo]()
                
                // Download the photos on the global queue
                for (remoteURL, localURL) in photos {
                    let newPhoto = Photo(localPath: localURL.path!, remotePath: remoteURL.absoluteString, pin: pin, context: CoreDataManager.sharedInstance().managedObjectContext!)
                    newPhotos.append(newPhoto)
                    print("Downloading photo from \(newPhoto.remotePath) to \(newPhoto.localPath)")
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        if let _ = self.downloadImageForPhoto(newPhoto) {
                            print("Downloaded photo from \(newPhoto.remotePath)")
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                newPhoto.downloaded = true
                                do {
                                    try CoreDataManager.sharedInstance().managedObjectContext!.save()
                                } catch {
                                    print("Error saving context")
                                }
                            })
                        } else {
                            print("Failed to download photo from \(newPhoto.remotePath)")
                        }
                    })
                }
                
                do {
                    try CoreDataManager.sharedInstance().managedObjectContext!.save()
                } catch {
                    print("Error saving context")
                }

                completion(photos: newPhotos, pageCount: pageCount, error: nil)
            }
        }
    }
    
    func downloadImageForPhoto(photo: Photo) -> NSData? {
        guard let remoteURL = NSURL(string: photo.remotePath) else {
                print("Invalid remote path")
                fatalError()
        }
        
        if let data = NSData(contentsOfURL: remoteURL) {
            if (!data.writeToFile(photo.localPath, atomically: true)) {
                print("Failed to write to URL: \(photo.localPath)")
                return nil
            }
            return data
        }

        return nil
    }
    
    private func getImageFromFlickr(arguments: [String: String], completion: (photoPaths: [[String: AnyObject]], pageCount: Int, error: NSError?) -> ()) {
        
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
                    
                    // Get the `photos` dictionary from the parsed response
                    let photos = parsedResult["photos"] as! [String: AnyObject]
                    
                    // See if we got any results
                    let total = Int((photos["total"] as! String))!
                    if total > 0 {
                        // Store the number last page download and the total number of pages
                        let lastPage = photos["page"] as! Int
                        let lastPageCount = photos["pages"] as! Int
                        print("Received page \(lastPage) of \(lastPageCount) pages, with \(total) photos!")
                        
                        let photoArray = photos["photo"] as! [[String: AnyObject]]
                        completion(photoPaths: photoArray, pageCount: lastPageCount, error: nil)
                    }
                    else {
                        completion(photoPaths: [[String: AnyObject]](), pageCount: 0, error: NSError(domain: "FlickrClient", code: -1, userInfo: nil))
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
        
        let urlString = APIConstants.BASE_URL + methodString
        
        if let components = NSURLComponents(string: urlString) {
            print("Got components")
            return components.URL
        }
        
        return nil
    }

    private func createBoundingBox(lat: Double, _ lon: Double) -> String {
        return "\(floor(lon)),\(floor(lat)),\(ceil(lon)),\(ceil(lat))"
    }

}
