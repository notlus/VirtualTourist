//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/8/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }
    
    // ** For testing **
    private var flickrClient = FlickrClient()
    private lazy var documentsDirectory: NSURL = {
        NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        }()
    
    private lazy var photosPath: NSURL = {
        self.documentsDirectory.URLByAppendingPathComponent("VirtualTouristPhotos/")
        }()

    private var lastRegion: MKCoordinateRegion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lat = 0.0 //34.0500
        let lon = 0.0 //118.25
        
        flickrClient.downloadImagesForLocation(lat, longitude: lon, storagePath: photosPath) { (error) -> () in
            println("Got some imaages")
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let region = loadRegion() {
            println("Found stored region data")
            mapView.region = region
        }
    }
    
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            println("Handling `Began` state for gesture")
            let touchPoint = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "PinAnnotation")
            mapView.addAnnotation(annotation)
            saveRegion(mapView.region)
        } else
        {
            println("Ignoring state")
        }
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        println("didSelectAnnotationView")
        performSegueWithIdentifier("ShowPhotoAlbumViewController", sender: self)
    }
    
    private func loadRegion() -> MKCoordinateRegion? {
        println("Attempting to load region")
        
        let defaults = NSUserDefaults.standardUserDefaults()

        // Load the span and center from NSUserDefaults
        let span = MKCoordinateSpanMake(defaults.doubleForKey("latitudeDelta"), defaults.doubleForKey("longitudeDelta"))
        
        let center = CLLocationCoordinate2DMake(defaults.doubleForKey("latitude"), defaults.doubleForKey("longitude"))

        if center.latitude == 0 && center.longitude == 0 && span.latitudeDelta == 0 && span.longitudeDelta == 0 {
            // Nothing found
            return nil
        }
        
        let region = MKCoordinateRegionMake(center, span)
        
        return region
    }
    
    private func saveRegion(region: MKCoordinateRegion) {
        println("Saving region")
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let latitude = region.center.latitude
        let longitude = region.center.longitude
        
        defaults.setDouble(latitude, forKey: "latitude")
        defaults.setDouble(longitude, forKey: "longitude")
        defaults.setDouble(region.span.latitudeDelta, forKey: "latitudeDelta")
        defaults.setDouble(region.span.longitudeDelta, forKey: "longitudeDelta")
    }
    
}
