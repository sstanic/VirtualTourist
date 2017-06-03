//
//  ImageData+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 30.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ImageData {

    @NSManaged var image: Data?
    @NSManaged var url: String?
    @NSManaged var pin: Pin?

}
