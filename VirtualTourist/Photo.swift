//
//  Photo.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/13/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import Foundation
import CoreData

class Photo: NSManagedObject {
    @NSManaged var path: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
}