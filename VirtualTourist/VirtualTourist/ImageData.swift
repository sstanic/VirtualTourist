//
//  ImageData.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 20.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation
import CoreData

class ImageData: NSManagedObject {

    convenience init(url: String, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entityForName("ImageData",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.url = url
        }
        else {
            fatalError("Unable to find Entity name!")
        }
    }
}
