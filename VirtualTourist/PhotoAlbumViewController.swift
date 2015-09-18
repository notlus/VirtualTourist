//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/8/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!

    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try fetchedResultsController.performFetch()
            fetchedResultsController.delegate = self
        }
        catch {
            print("Fetch failed")
            fatalError()
        }
        
        print("fetched \(fetchedResultsController.fetchedObjects!.count) photos")
    }

    override func viewWillAppear(animated: Bool) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: (pin.latitude as NSString).doubleValue, longitude: (pin.longitude as NSString).doubleValue)
        
        // Add the annotation on the main queue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mapView.addAnnotation(annotation)
            self.mapView.centerCoordinate = annotation.coordinate
            let span = MKCoordinateSpanMake(1.0, 1.0)
            let region = MKCoordinateRegion(center: self.mapView.centerCoordinate, span: span)
            self.mapView.setRegion(region, animated: false)
        })
    }

    @IBAction func newCollection() {
        print("Creating collection")
    }
    
    // MARK: - Core Data
    
    private var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "path", ascending: true)]
        // TODO: fix
//        fetchRequest.predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", self.pin.latitude, self.pin.longitude)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Configure the cell
        let reuseIdentifier = "PhotoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) // as! UICollectionViewCell
        cell.backgroundColor = UIColor.blueColor()
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if let image = getImageForPhoto(photo) {
            cell.contentView.addSubview(UIImageView(image: image))
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("Selected cell")
    }
    
    // MARK: FetchedResultsControllerDelegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("controllerWillChangeContent")
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
            case .Insert:
                collectionView!.insertSections(NSIndexSet(index: sectionIndex))
                
            case .Delete:
                collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
                
            default:
                return
            }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                
            case .Delete:
                collectionView!.deleteItemsAtIndexPaths([indexPath!])
                
            case .Update:
                let cell = collectionView!.cellForItemAtIndexPath(indexPath!)! // as! ActorTableViewCell
                let photo = fetchedResultsController.objectAtIndexPath(indexPath!) as! Photo
                if let image = getImageForPhoto(photo) {
                    cell.contentView.addSubview(UIImageView(image: image))
                }

                // TODO: Handle
                cell.backgroundColor = UIColor.orangeColor()
                
            case .Move:
                collectionView!.deleteItemsAtIndexPaths([indexPath!])
                collectionView!.insertItemsAtIndexPaths([newIndexPath!])
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // TODO: Handle
//        self.tableView.endUpdates()
    }
    
    private func getImageForPhoto(photo: Photo) -> UIImage? {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        var image: UIImage?
        if let fullPath = NSURL(string: photo.path, relativeToURL: appDelegate.photosPath) {
            image = UIImage(contentsOfFile: fullPath.path!)
        }
        return image
    }
}
