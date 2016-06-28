//
//  WSClientConstants.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 09.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation

extension WSClient {
    
    //# MARK: Authentication
    struct AuthConstants {
        
        // URL
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest/"
    }

    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Page = "page"
        static let PerPage = "per_page"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "4120b4b57e0c20e206965d809d8d59e4"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
        static let PerPage = 20
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let PerPage = "perpage"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        
        static let OKStatus = "ok"
    }
    
    //# MARK: Data Access
    struct DataConstants {
        
        static let Timeout = 10
    }
    
    //#MARK: Error Messages
    struct ErrorMessage {
        
        static let NetworkTimeout = "Network timeout. Please check your network connection."
        static let GeneralHttpRequestError = "Http request error. Error message: "
        static let StatusCodeFailure = "Your request returned a status code other than 2xx."
        static let NoDataFoundInRequest = "No data was returned by the request."
        static let JsonParseError = "Could not parse the data as JSON. Data: "
        
        static let HttpDataTaskFailed = "Http data task failed. Cannot convert result data."
    }
}