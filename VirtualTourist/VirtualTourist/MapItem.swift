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

    let subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    var pin: Pin?
    
    init(title: String, subtitle: String, location: CLLocationCoordinate2D) {
        
        self.title = title
        self.subtitle = subtitle
        self.coordinate = location
        
        super.init()
    }
    
    var title: String? {
        
        willSet { willChangeValueForKey("title") }
        didSet { didChangeValueForKey("title") }
    }
}