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
        if let ent = NSEntityDescription.entity(forEntityName: "Pin",
                                                       in: context){
            self.init(entity: ent, insertInto: context)
            self.title = title
            self.latitude = latitude as NSNumber
            self.longitude = longitude as NSNumber
            self.imageSet = 1
        }
        else {
            fatalError("Unable to find Entity name!")
        }
    }
}
