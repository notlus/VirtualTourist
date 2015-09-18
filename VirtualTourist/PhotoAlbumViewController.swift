//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/8/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import CoreData
import UIKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            print("Fetch failed")
            fatalError()
        }
        
        print("fetched \(fetchedResultsController.fetchedObjects!.count) photos")
    }

    override func viewWillAppear(animated: Bool) {
        if pin!.photos.isEmpty {
            // Get photos from Flickr
            print("No photos available")
//            flickrClient.downloadImagesForLocation(pin!.latitude, longitude: pin!.longitude, storagePath: photosPath) { (error) -> () in
//                print("Got some imaages")
//            }

        }
    }

    // MARK: - Core Data
    
    private var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "path", ascending: true)]
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
        let reuseIdentifier = "PhotoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) // as! UICollectionViewCell
        cell.backgroundColor = UIColor.blueColor()
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let image = UIImage(contentsOfFile: photo.path)
        cell.contentView.addSubview(UIImageView(image: image))
        // Configure the cell
//        cell.memeImageView.image = appDelegate.memes[indexPath.row].memedImage
//        cell.backgroundColor = UIColor.blackColor()
//        cell.delegate = self
//        cell.deleteButton.hidden = editMode ? false : true
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("Selected cell")
        // Create the detail view controller
//        let detailViewController = storyboard!.instantiateViewControllerWithIdentifier("DetailViewController")! as! DetailViewController
        
        // Set the index of the selected table view entry
//        detailViewController.memeIndex = indexPath.row
//        navigationController!.pushViewController(detailViewController, animated: true)
    }

}
