//
//  MapItem.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 10.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation
import MapKit

class MapItem: NSObject, MKAnnotation {

    //# MARK: Attributes
    var coordinate: CLLocationCoordinate2D
    
    var pin: Pin?
    
    var title: String? {
        
        willSet { willChangeValue(forKey: "title") }
        didSet { didChangeValue(forKey: "title") }
    }
    
    
    //# MARK: Init
    init(title: String, location: CLLocationCoordinate2D) {
        
        self.title = title
        self.coordinate = location
        
        super.init()
    }
}
