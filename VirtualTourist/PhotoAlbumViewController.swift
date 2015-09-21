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

class PhotoAlbumViewController: UIViewController,
                                NSFetchedResultsControllerDelegate,
                                UICollectionViewDelegate,
                                UICollectionViewDataSource,
                                UICollectionViewDelegateFlowLayout {
    
    // MARK: Outlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel! {
        didSet {
            noImagesLabel.hidden = true
        }
    }

    // MARK: Private Properties
    
    private let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    private var selectedPhotos = Set<NSIndexPath>() {
        didSet {
            if selectedPhotos.count > 0 {
                collectionButton.setTitle("Remove Selected Pictures", forState: .Normal)
            }
            else {
                collectionButton.setTitle("New Collection", forState: .Normal)
            }
        }
    }
    
    var updating = false
    
    /// A dictionary that maps `NSFetchedResultsChangeType`s to an arry of `NSIndexPaths`s
    private var objectChanges = [NSFetchedResultsChangeType: [NSIndexPath]]()
    
    // MARK: Public Properties
    
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
        if fetchedResultsController.fetchedObjects!.count == 0 {
//            collectionView.hidden = true
//            noImagesLabel.hidden = false
            updating = true
        } else {
            updating = false
        }
    }

    override func viewWillAppear(animated: Bool) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        
        // Add the annotation on the main queue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mapView.addAnnotation(annotation)
            self.mapView.centerCoordinate = annotation.coordinate
            let span = MKCoordinateSpanMake(1.0, 1.0)
            let region = MKCoordinateRegion(center: self.mapView.centerCoordinate, span: span)
            self.mapView.setRegion(region, animated: false)
        })
    }

    // MARK: Actions
    
    @IBAction func newCollection() {
        if selectedPhotos.isEmpty {
            print("Creating collection")
            
            collectionButton.enabled = false
            updating = true
            
            // Delete existing photos
            if let photos = fetchedResultsController.fetchedObjects as? [Photo] {
                for photoObject in photos {
                    sharedContext.deleteObject(photoObject)
                }
                
                do {
                    try sharedContext.save()
                } catch {
                    print("Error saving context")
                }
            }
            
            // Load new photos
            FlickrClient.sharedInstance.downloadImagesForLocation(pin.latitude, longitude: pin.longitude,
                pageCount: pin.pageCount, storagePath: appDelegate.photosPath) { (photos, pages, error) -> () in
                
                // Update the pin with the number of pages associated with the location
                self.pin.pageCount = pages
                    
                if let photos = photos {
                    print("Saving \(photos.count) photos")
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        for photo in photos {
                            let _ = Photo(path: photo.path!, pin: self.pin, context: self.sharedContext)
                        }
                    
                        do {
                            try self.sharedContext.save()
                        } catch {
                            print("Error saving context")
                        }
                        
                        self.collectionButton.enabled = true
                        self.updating = false
                        self.collectionView.reloadData()
                    })
                }
            }

        } else {
            print("Removing \(selectedPhotos.count) photos")
            
            for photoIndex in selectedPhotos {
                sharedContext.deleteObject(fetchedResultsController.objectAtIndexPath(photoIndex) as! Photo)
            }
            
            selectedPhotos.removeAll()
            
            do {
                try sharedContext.save()
            } catch {
                print("Failed to save context")
            }
        }
    }
    
    // MARK: - Core Data
    
    private var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext!
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "path", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin.latitude == %lf AND pin.longitude == %lf", self.pin.latitude, self.pin.longitude)
      
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if updating {
            return 51
        }
        
        return (fetchedResultsController.sections?[section])?.numberOfObjects ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Configure the cell
        let reuseIdentifier = "PhotoCell"
        let photoCell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewPhotoCell
        
        if updating {
//            photoCell.activityView.hidden = false
            photoCell.activityView.startAnimating()
            photoCell.photoView.hidden = true
        }
        else {
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            if let image = getImageForPhoto(photo) {
                photoCell.photoView.image = image
            }
        }
        
        photoCell.photoView.alpha = 1.0
        
        return photoCell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photoCell = collectionView.cellForItemAtIndexPath(indexPath) as! CollectionViewPhotoCell
        
        if selectedPhotos.contains(indexPath) {
            // Unselect photo
            photoCell.photoView.alpha = 1.0
            selectedPhotos.remove(indexPath)
        } else {
            // Select photo
            selectedPhotos.insert(indexPath)
            photoCell.photoView.alpha = 0.25
        }
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(120, 120)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: -60, left: 10, bottom: 0, right: 10)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0.0
    }

    // MARK: FetchedResultsControllerDelegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("controllerWillChangeContent")
        updating = false
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            // TODO: Handle
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
                if let insertIndexPath = newIndexPath {
                    var arr = objectChanges[type]
                    if arr == nil {
                        arr = [NSIndexPath]()
                    }
                    arr?.append(insertIndexPath)
                    objectChanges[type] = arr
                }
                
            case .Delete:
                if let deleteIndexPath = indexPath {
                    var arr = objectChanges[type]
                    if arr == nil {
                        arr = [NSIndexPath]()
                    }
                    arr?.append(deleteIndexPath)
                    objectChanges[type] = arr
                }
                
            case .Update:
                if let updateIndexPath = indexPath {
                    var arr = objectChanges[type]
                    if arr == nil {
                        arr = [NSIndexPath]()
                    }
                    arr?.append(updateIndexPath)
                    objectChanges[type] = arr
                }

//            case .Move:
//                // TODO: Handle or remove
//                if let old = indexPath, let new = newIndexPath {
//                    objectChanges[type] = [old, new]
//                }
                
            default:
                fatalError("Unsupported change type: \(type)")
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // TODO: Handle
        print("controllerDidChangeContent")
        collectionView.performBatchUpdates({ () -> Void in

            for (changeType, indexPaths) in self.objectChanges {
                switch changeType {
                case .Delete:
                    self.collectionView!.deleteItemsAtIndexPaths(indexPaths)
                
                case .Insert:
                    self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                    
                case .Update:
                    self.collectionView!.reloadItemsAtIndexPaths(indexPaths)
//                case .Move:
                default:
                    fatalError("Unexpected change type: \(changeType)")
                }
            }
            
            }) { (finished) -> Void in
                print("Finished with batch updates")
                
                self.objectChanges.removeAll()
                self.collectionView.reloadData()
        }
    }
    
    private func getImageForPhoto(photo: Photo) -> UIImage? {
        return UIImage(contentsOfFile: photo.path)
    }
}
