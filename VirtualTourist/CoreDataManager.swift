//
//  CoreDataManager.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/13/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import Foundation
import CoreData

private let SQLITE_FILE_NAME = "VirtualTourist.sqlite"
private let kCoreDataErrorDomain = "CoreData"

class CoreDataManager {
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> CoreDataManager {
        struct Static {
            static let instance = CoreDataManager()
        }
    
        return Static.instance
    }
    
    // MARK: - The Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        
        print("Instantiating the applicationDocumentsDirectory property")
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a
        // fatal error for the application not to be able to find and load its model.

        print("Instantiating the managedObjectModel property")
        
        let modelURL = NSBundle.mainBundle().URLForResource("VirtualTourist", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    /**
     * The Persistent Store Coordinator is an object that the Context uses to interact with the underlying file system. Usually
     * the persistent store coordinator object uses an SQLite database file to save the managed objects. But it is possible to 
     * configure it to use XML or other formats. 
     *
     * Typically you will construct your persistent store manager exactly like this. It needs two pieces of information in order
     * to be set up:
     *
     * - The path to the sqlite file that will be used. Usually in the documents directory
     * - A configured Managed Object Model. See the next property for details.
     */
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and 
        // return a coordinator, having added the store for the application to it. This property is
        // optional since there are legitimate error conditions that could cause the creation of the 
        // store to fail.
        // Create the coordinator and store
        
        print("Instantiating the persistentStoreCoordinator property")
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        
        print("sqlite path: \(url.path!)")
        
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error as NSError {
            coordinator = nil
            var dict = [String : AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: kCoreDataErrorDomain, code: 100, userInfo: dict)

            // Left in for development.
            NSLog("Unresolved error \(error), \(error.userInfo)")
            abort()
        } catch {
            // Unexpected error
            fatalError()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        
        print("Instantiating the managedObjectContext property")
        
        // Returns the managed object context for the application (which is already bound to the persistent 
        // store coordinator for the application.) This property is optional since there are legitimate error
        // conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext() {

        guard let context = managedObjectContext else {
            fatalError()
        }
        
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                NSLog("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }
}
