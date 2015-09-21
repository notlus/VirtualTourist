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
    
    var updating = false {
        willSet {
            print("will set updating from \(updating) to \(newValue)")
        }
        
        didSet {
            print("did set updating to \(updating)")
        }
    }
    
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
            // No photos downloaded yet, so try to get some
            
            updating = true
            
            FlickrClient.sharedInstance.downloadImagesForLocation(pin, pageCount: pin.pageCount, storagePath: appDelegate.photosPath) { (photos, pages, error) -> () in
                    
                    if let photos = photos {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            // Update the pin with the number of pages associated with the location
                            self.pin.pageCount = pages
                            
                            print("Saved \(photos.count) photos")
                            
                            self.collectionButton.enabled = true
                            self.updating = false
                            self.collectionView.reloadData()
                        })
                    }
            }
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
            print("Retrieving new collection")
            
            collectionButton.enabled = false
            
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
            
            updating = true
            
            // Load new photos
            FlickrClient.sharedInstance.downloadImagesForLocation(pin, pageCount: pin.pageCount, storagePath: appDelegate.photosPath) { (photos, pages, error) -> () in
                
                if let photos = photos {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        // Update the pin with the number of pages associated with the location
                        self.pin.pageCount = pages

                        print("Saved \(photos.count) photos")

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
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "localPath", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin.latitude == %lf AND pin.longitude == %lf", self.pin.latitude, self.pin.longitude)
      
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fetchedResultsController.sections?[section])?.numberOfObjects ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Configure the cell
        let reuseIdentifier = "PhotoCell"
        let photoCell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewPhotoCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.downloaded {
            photoCell.photoView.hidden = false
            photoCell.overlayView.hidden = true
            photoCell.activityView.stopAnimating()
            if let image = getImageForPhoto(photo) {
                photoCell.photoView.image = image
            }
        } else {
            print("Photo not downloaded!")
            photoCell.activityView.startAnimating()
            photoCell.photoView.hidden = true
            photoCell.overlayView.hidden = false
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
                
            default:
                fatalError("Unsupported change type: \(type)")
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // TODO: Handle
        print("controllerDidChangeContent")
        
        if updating {
            print("updating, so returning")
            return
        }

        print("*** Performing batch update ***")
        collectionView.performBatchUpdates({ () -> Void in

            for (changeType, indexPaths) in self.objectChanges {
                switch changeType {
                case .Delete:
                    print("Deleting \(indexPaths.count) index paths")
                    self.collectionView.deleteItemsAtIndexPaths(indexPaths)
                
                case .Insert:
                    print("Inserting \(indexPaths.count) index paths")
                    self.collectionView.insertItemsAtIndexPaths(indexPaths)
                    
                case .Update:
                    print("Updating \(indexPaths.count) index paths")
                    self.collectionView.reloadItemsAtIndexPaths(indexPaths)

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
        return UIImage(contentsOfFile: photo.localPath)
    }
}
