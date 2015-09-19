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
    
    private let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    

    // MARK: Outlets
    
    @IBOutlet weak var deletePinsLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            print("Setting delegate")
            mapView.delegate = self
        }
    }
    
    // MARK: Actions
    
    @IBAction func handleEdit(sender: UIBarButtonItem) {
        if !editing {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "handleEdit:")
            deletePinsLabel.hidden = false
            editing = true
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "handleEdit:")
            deletePinsLabel.hidden = true
            if sharedContext.hasChanges {
                do {
                    try sharedContext.save()
                } catch {
                    print("Error saving context")
                }
            }
            editing = false
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
        } else {
            print("Ignoring state")
        }
    }
    
    // MARK: View Management
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Virtual Tourist"
        
        if (!NSFileManager.defaultManager().fileExistsAtPath(appDelegate.photosPath.path!)) {
        
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(appDelegate.photosPath, withIntermediateDirectories: false, attributes: nil)
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
        
        print("fetched \(fetchedResultsController.fetchedObjects!.count) pins")
        
        if let pins = fetchedResultsController.fetchedObjects as? [Pin] {
            for pin in pins {
                addAnnotation(pin)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let region = loadRegion() {
            print("Found stored region data")
            mapView.region = region
        }
    }

    private func addAnnotation(pin: Pin) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: (pin.latitude as NSString).doubleValue, longitude: (pin.longitude as NSString).doubleValue)
        
        // Add the annotation on the main queue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mapView.addAnnotation(annotation)
        })
    }
    
    private func saveLocation(latitude: Double, longitude: Double) {
        // Create a new `Pin` instance
        let newPin = Pin(latitude: latitude, longitude: longitude, context: sharedContext)
        CoreDataManager.sharedInstance().saveContext()
        
//        sharedContext.performBlock { () -> Void in
            print("Downloading from Flickr")
            
//            FlickrClient.sharedInstance.downloadImagesForLocation(0, longitude: 0, storagePath: self.appDelegate.photosPath) { (photos, error) -> () in
//                print("Saving \(photos?.count) photos")
//                for photo in photos! {
//                    let _ = Photo(path: photo.relativePath!, pin: newPin, context: self.sharedContext)
//                }
        
//                CoreDataManager.sharedInstance().saveContext()
//            }
    }
    
    private func findPin(annotation: MKAnnotation) -> Pin {
        let nf = NSNumberFormatter()
        nf.numberStyle = .DecimalStyle
        
        let latitude = nf.stringFromNumber(annotation.coordinate.latitude)!
        let longitude = nf.stringFromNumber(annotation.coordinate.longitude)!

        fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("performFetch() failed")
        }
        
        let pins = fetchedResultsController.fetchedObjects as! [Pin]
        return pins[0]
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var v = mapView.dequeueReusableAnnotationViewWithIdentifier("MapViewAnnotation") as? MKPinAnnotationView
        if v == nil {
            // No queued view, so create one
            v = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MapViewAnnotation") as MKPinAnnotationView
        }

        v!.canShowCallout = false
        v!.animatesDrop = true

        return v
    }

    private var tappedPin: CLLocationCoordinate2D?
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("didSelectAnnotationView")
        
        if editing == false {
            saveRegion(mapView.region)
            tappedPin = view.annotation?.coordinate
            performSegueWithIdentifier("ShowPhotoAlbumViewController", sender: self)
        } else {
            print("Deleting pin")
            let pin = findPin(view.annotation!)
            sharedContext.deleteObject(pin)
            mapView.removeAnnotation(view.annotation!)
//            if let pins = fetchedResultsController.fetchedObjects as? [Pin] {
//                mapView.removeAnnotation(view.annotation!)
//            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("Preparing for segue")
        
        if segue.identifier == "ShowPhotoAlbumViewController" {
            let photosVC = segue.destinationViewController as! PhotoAlbumViewController
            photosVC.pin = Pin(latitude: tappedPin!.latitude, longitude: tappedPin!.longitude, context: sharedContext)
        }
    }
    
    // MARK: Load and save region data
    
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
