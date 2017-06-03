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
        if let ent = NSEntityDescription.entity(forEntityName: "ImageData",
                                                       in: context){
            self.init(entity: ent, insertInto: context)
            self.url = url
        }
        else {
            fatalError("Unable to find Entity name!")
        }
    }
}
