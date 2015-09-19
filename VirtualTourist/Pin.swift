//
//  Pin.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/8/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
class Pin: NSManagedObject {
    @NSManaged var latitude: String
    @NSManaged var longitude: String
    @NSManaged var photos: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Pin" type.
        guard let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) else {
            print("Failed to get the `Pin` entity")
            fatalError()
        }

        // Call the superclass to insert into the context
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        // Initialize properties
        // TODO: Store more than 2 digits of accuracy
        let nf = NSNumberFormatter()
        nf.numberStyle = .DecimalStyle

        self.latitude = nf.stringFromNumber(latitude)!
        self.longitude = nf.stringFromNumber(longitude)!
    }
}