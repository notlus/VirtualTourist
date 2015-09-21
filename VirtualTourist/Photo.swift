//
//  Photo.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/13/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
class Photo: NSManagedObject {
    @NSManaged var localPath: String
    @NSManaged var remotePath: String
    @NSManaged var pin: Pin
    @NSManaged var downloaded: Bool
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(localPath: String, remotePath: String, pin: Pin, context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) else {
            print("Failed to get the `Photo` entity")
            fatalError()
        }
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Initialize properties
        self.localPath = localPath
        self.remotePath = remotePath
        self.pin = pin
        self.downloaded = false
    }
    
    override func prepareForDeletion() {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(localPath)
        } catch {
            print("Failed to delete \(localPath)")
        }
    }
}