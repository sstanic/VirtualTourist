//
//  FlickrData.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 28.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation

struct FlickrData {
    
    //# MARK: Attributes
    var urls = [String]()
    var pages = Int()
    
    
    //#MARK: Initializer
    init (urls: [String], pages: Int) {
        self.urls = urls
        self.pages = pages
    }
}