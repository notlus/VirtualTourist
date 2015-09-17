//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/8/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            print("Setting delegate")
            mapView.delegate = self
        }
    }
    
    // ** For testing **
//    private var flickrClient = FlickrClient()
    
    private lazy var documentsDirectory: NSURL = {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    }()
    
    private lazy var photosPath: NSURL = {
        self.documentsDirectory.URLByAppendingPathComponent("VirtualTouristPhotos/")
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (!NSFileManager.defaultManager().fileExistsAtPath(photosPath.path!)) {
        
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(photosPath, withIntermediateDirectories: false, attributes: nil)
            }
            catch {
                fatalError()
            }
        }
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("performFetch failed")
        }
        
        print("fetched \(fetchedResultsController.fetchedObjects)")
        
        if let pins = fetchedResultsController.fetchedObjects as? [Pin] {
            for pin in pins {
                addAnnotation(pin)
            }
        }
        
//        fetchedResultsController.delegate = self
        
//        let lat = 0.0 //34.0500
//        let lon = 0.0 //118.25
       
//        flickrClient.downloadImagesForLocation(lat, longitude: lon, storagePath: photosPath) { (error) -> () in
//            print("Got some imaages")
//        }
    }
    
    private func addAnnotation(pin: Pin) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        
        // Add the annotation on the main queue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mapView.addAnnotation(annotation)
        })
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let region = loadRegion() {
            print("Found stored region data")
            mapView.region = region
        }
    }
    
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            print("Handling `Began` state for gesture")
            let touchPoint = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            saveLocation(coordinate.latitude, longitude: coordinate.longitude)
            
            // TODO: Determine where the zoom level should be saved
            saveRegion(mapView.region)
        } else
        {
            print("Ignoring state")
        }
    }
    
    private func saveLocation(latitude: Double, longitude: Double) {
        // Create a new `Pin` instance
        _ = Pin(latitude: latitude, longitude: longitude, context: sharedContext)
        CoreDataManager.sharedInstance().saveContext()
        
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let v = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MapViewAnnotation") as MKPinAnnotationView
        v.pinColor = .Green
        v.animatesDrop = true
        return v
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("didSelectAnnotationView")
        let coordinate = view.annotation?.coordinate
        performSegueWithIdentifier("ShowPhotoAlbumViewController", sender: self)
    }
    
    private func loadRegion() -> MKCoordinateRegion? {
        print("Attempting to load region")
        
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
        print("Saving region")
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let latitude = region.center.latitude
        let longitude = region.center.longitude
        
        defaults.setDouble(latitude, forKey: "latitude")
        defaults.setDouble(longitude, forKey: "longitude")
        defaults.setDouble(region.span.latitudeDelta, forKey: "latitudeDelta")
        defaults.setDouble(region.span.longitudeDelta, forKey: "longitudeDelta")
    }
    
    // MARK: - Core Data
    
    private var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()

}
