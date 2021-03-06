//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 28.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var title: String?
    @NSManaged var imageSet: NSNumber?
    @NSManaged var imageDatas: NSSet?

}
