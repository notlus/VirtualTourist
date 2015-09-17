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
    @NSManaged var path: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(path: String, context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) else {
            print("Failed to get the `Photo` entity")
            fatalError()
        }
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Initialize properties
        self.path = path
    }
}