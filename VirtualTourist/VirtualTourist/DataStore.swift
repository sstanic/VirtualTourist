//
//  DataStore.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 10.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class DataStore {
    
    //# MARK: Attributes
    let stack = CoreDataStack(modelName: "VirtualTourist")!
    var pins = [Pin]()
    
    
    //# MARK: - Data Model
    func createPin(_ latitude: Double, longitude: Double, title: String) -> Pin {

        let pin = Pin(latitude: latitude, longitude: longitude, title: title, context: self.stack.context)
        self.pins.append(pin)
        
        return pin
    }
    
    fileprivate func createImageData(_ url: String) -> ImageData {
        
        let imageData = ImageData(url: url, context: stack.context)
        return imageData
    }
    
    func deleteImageData(_ imageData: ImageData, deleteCompletionHandler: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        stack.context.delete(imageData)

        saveContext() { (success, error) in
            
            if success {
                deleteCompletionHandler(true, nil)
            }
            else {
                deleteCompletionHandler(false, error)
            }
        }
    }
    
    func saveContext(_ saveCompletionHandler: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        Utils.GlobalMainQueue.async {
            if self.stack.context.hasChanges {
                do {
                    try self.stack.context.save()
                    
                    saveCompletionHandler(true, nil)
                }
                catch {
                    let userInfo = [NSLocalizedDescriptionKey : "Error occured in saveContext"]
                    print(userInfo)
                    
                    saveCompletionHandler(false, NSError(domain: "saveContext", code: 1, userInfo: userInfo))
                }
            }
        }
    }
    
    func loadPins(_ loadPinsCompletionHandler: (_ success: Bool, _ error: NSError?) -> Void) {

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Pin", in: self.stack.context)
        fetchRequest.entity = entityDescription
        
        do {
            let result = try self.stack.context.fetch(fetchRequest)
            self.pins = result as! [Pin]
            
            loadPinsCompletionHandler(true, nil)
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
            
            loadPinsCompletionHandler(false, fetchError)
        }
    }
    
    
    //# MARK: - Load/Access Images
    func getImages(_ pin: Pin, getCompletionHandler : @escaping (_ success: Bool, _ results: Pin, _ error: NSError?) -> Void) {
        
        let lat = Double(pin.latitude!)
        let lon = Double(pin.longitude!)
        let page = 1
        
        if pin.imageDatas?.count > 0 {
            print("Using locally saved image data.")
            
            getCompletionHandler(true, pin, nil)
        }
        else {
            print("Loading image data from web service.")
            
            WSClient.sharedInstance().getImages(lat, longitude: lon, page: page) { (success, results, error) in
                
                if success {
                    Utils.GlobalMainQueue.async {
                        
                        var imageDatas = [ImageData]()
                        
                        // create image entities
                        for result in results!.urls {
                            
                            let imageData = self.createImageData(result)
                            imageDatas.append(imageData)
                        }
                        
                        pin.imageDatas = NSSet(array: imageDatas)
                        
                        self.saveContext() { (success, error) in
                            
                            if !success {
                                print(error as Any)
                                getCompletionHandler(false, pin, error)
                            }
                        }
                        
                        // return with success
                        getCompletionHandler(true, pin, nil)
                    }
                }
                else {
                    print(error as Any)
                    getCompletionHandler(false, pin, error)
                }
            }
        }
    }

    func loadNewImages(_ pin: Pin, reloadCompletionHandler : @escaping (_ success: Bool, _ results: Pin, _ error: NSError?) -> Void) {
        
        let lat = Double(pin.latitude!)
        let lon = Double(pin.longitude!)
        
        let page = Int(pin.imageSet!) + 1
        
        print("Adding additional (new) images from web service.")
        
        WSClient.sharedInstance().getImages(lat, longitude: lon, page: page) { (success, results, error) in
            
            if success {
                Utils.GlobalMainQueue.async {
                    
                    var imageDatas = [ImageData]()
                    
                    if Constants.AddImagesWithoutDeletion {
                        imageDatas = pin.imageDatas?.allObjects as! [ImageData]
                    }
                    
                    // create image entities
                    for result in results!.urls {
                        
                        let imageData = self.createImageData(result)
                        
                        // check existing image data, if url is known
                        let filter = NSPredicate(format: "url == %@", result)
                        let filteredImages = pin.imageDatas?.filtered(using: filter)
                        
                        if Constants.AddImagesWithoutDeletion {
                            
                            // if there is no result, add image to set of images
                            if filteredImages?.count == 0 {
                                imageDatas.append(imageData)
                            }
                        }
                        else {
                            
                            // if image is already loaded, use it
                            if filteredImages?.count > 1 {
                                let currentImageData = filteredImages?.first as! ImageData
                                imageData.image = currentImageData.image
                            }
                            
                            imageDatas.append(imageData)
                        }
                    }
                    
                    // remove old images (outside of pin region)
                    for id in pin.imageDatas! {
                        
                        if !imageDatas.contains(id as! ImageData) {
                            DataStore.sharedInstance().deleteImageData(id as! ImageData) { (success, error) in
                                
                                if !success {
                                    print(error as Any)
                                    reloadCompletionHandler(false, pin, error)
                                    return
                                }
                            }
                        }
                    }
                    
                    pin.imageDatas = NSSet(array: imageDatas)
                    pin.imageSet = page as NSNumber
                    
                    // if no more pages are available, reset counter (keep it simple)
                    if Int(pin.imageSet!) >= results?.pages {
                        pin.imageSet = 0
                    }
                    
                    self.saveContext() { (success, error) in
                        
                        if !success {
                            print(error as Any)
                            reloadCompletionHandler(false, pin, error)
                        }
                    }
                    
                    // return with success
                    reloadCompletionHandler(true, pin, nil)
                }
            }
            else {
                print(error as Any)
                reloadCompletionHandler(false, pin, error)
            }
        }
    }
    
    func loadImagesAfterPinMoved(_ pin: Pin, reloadCompletionHandler : @escaping (_ success: Bool, _ results: Pin, _ error: NSError?) -> Void) {
        
        let lat = Double(pin.latitude!)
        let lon = Double(pin.longitude!)
        
        let page = 1
        
        print("Loading image data from web service and checking against available images.")

        WSClient.sharedInstance().getImages(lat, longitude: lon, page: page) { (success, results, error) in
            
            if success {
                Utils.GlobalMainQueue.async {
                    
                    var imageDatas = [ImageData]()
                    
                    // create image entities
                    for result in results!.urls {
                        
                        // check existing image data, if url is known
                        let filter = NSPredicate(format: "url == %@", result)
                        let filteredImages = pin.imageDatas?.filtered(using: filter)
                        
                        // if there is a match, add available image - else add new
                        if filteredImages?.count > 0 {
                            imageDatas.append(filteredImages?.first as! ImageData)
                        }
                        else {
                            let imageData = self.createImageData(result)
                            imageDatas.append(imageData)
                        }
                    }
                    
                    // remove old images (outside of pin region)
                    for id in pin.imageDatas! {
                        
                        if !imageDatas.contains(id as! ImageData) {
                            DataStore.sharedInstance().deleteImageData(id as! ImageData) { (success, error) in
                                
                                if !success {
                                    print(error as Any)
                                    reloadCompletionHandler(false, pin, error)
                                    return
                                }
                            }
                        }
                    }

                    pin.imageDatas = NSSet(array: imageDatas)
                    pin.imageSet = page as NSNumber
                    
                    // if no more pages are available, reset counter (keep it simple)
                    if Int(pin.imageSet!) >= results?.pages {
                        pin.imageSet = 0
                    }
                    
                    self.saveContext() { (success, error) in
                        
                        if !success {
                            print(error as Any)
                            reloadCompletionHandler(false, pin, error)
                            return
                        }
                    }
                    
                    // return with success
                    reloadCompletionHandler(true, pin, nil)
                }
            }
            else {
                print(error as Any)
                reloadCompletionHandler(false, pin, error)
            }
        }
    }

    
    //# MARK: - Shared Instance
    class func sharedInstance() -> DataStore {
        
        struct Singleton {
            static let sharedInstance = DataStore()
        }
        return Singleton.sharedInstance
    }
}
