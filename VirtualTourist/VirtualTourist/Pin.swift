//
//  Pin.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 20.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation
import CoreData

class Pin: NSManagedObject {

    convenience init(latitude: Double, longitude: Double, title: String, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entityForName("Pin",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.title = title
            self.latitude = latitude
            self.longitude = longitude
        }
        else {
            fatalError("Unable to find Entity name!")
        }
    }
}
