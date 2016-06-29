//
//  DataStore.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 10.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation
import CoreData

class DataStore {
    
    //# MARK: Attributes
    let stack = CoreDataStack(modelName: "VirtualTourist")!
    var pins = [Pin]()
    
    
    //# MARK: - Data Model
    func createPin(latitude: Double, longitude: Double, title: String, createPinCompletionHandler: (success: Bool, result: Pin, error: NSError?) -> Void) {

        let pin = Pin(latitude: latitude, longitude: longitude, title: title, context: self.stack.context)
        self.pins.append(pin)
        
        createPinCompletionHandler(success: true, result: pin, error: nil)
    }
    
    private func createImageData(url: String) -> ImageData {
        
        let imageData = ImageData(url: url, context: stack.context)
        return imageData
    }
    
    func deleteImageData(imageData: ImageData, deleteCompletionHandler: (success: Bool, error: NSError?) -> Void) {
        
        stack.context.deleteObject(imageData)

        saveContext() { (success, error) in
            
            if success {
                deleteCompletionHandler(success: true, error: nil)
            }
            else {
                deleteCompletionHandler(success: false, error: error)
            }
        }
    }
    
    func saveContext(saveCompletionHandler: (success: Bool, error: NSError?) -> Void) {
        
        dispatch_async(Utils.GlobalMainQueue) {
            if self.stack.context.hasChanges {
                do {
                    try self.stack.context.save()
                    
                    saveCompletionHandler(success: true, error: nil)
                }
                catch {
                    let userInfo = [NSLocalizedDescriptionKey : "Error occured in saveContext"]
                    print(userInfo)
                    
                    saveCompletionHandler(success: false, error: NSError(domain: "saveContext", code: 1, userInfo: userInfo))
                }
            }
        }
    }
    
    func loadPins(loadPinsCompletionHandler: (success: Bool, error: NSError?) -> Void) {

        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Pin", inManagedObjectContext: self.stack.context)
        fetchRequest.entity = entityDescription
        
        do {
            let result = try self.stack.context.executeFetchRequest(fetchRequest)
            self.pins = result as! [Pin]
            
            loadPinsCompletionHandler(success: true, error: nil)
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
            
            loadPinsCompletionHandler(success: false, error: fetchError)
        }
    }
    
    
    //# MARK: - Load/Access Images
    func getImages(pin: Pin, getCompletionHandler : (success: Bool, results: Pin, error: NSError?) -> Void) {
        
        let lat = Double(pin.latitude!)
        let lon = Double(pin.longitude!)
        let page = 1
        
        if pin.imageDatas?.count > 0 {
            print("Using locally saved image data.")
            
            getCompletionHandler(success: true, results: pin, error: nil)
        }
        else {
        
            print("Loading image data from web service.")
            
            WSClient.sharedInstance().getImages(lat, longitude: lon, page: page) { (success, results, error) in
                
                if success {
                    
                    dispatch_async(Utils.GlobalMainQueue) {
                        var imageDatas = [ImageData]()
                        
                        // create image entities
                        for result in results!.urls {
                            
                            let imageData = self.createImageData(result)
                            imageDatas.append(imageData)
                        }
                        
                        pin.imageDatas = NSSet(array: imageDatas)
                        
                        self.saveContext() { (success, error) in
                            
                            if !success {
                                print(error)
                                getCompletionHandler(success: false, results: pin, error: error)
                            }
                        }
                        
                        // return with success
                        getCompletionHandler(success: true, results: pin, error: nil)
                    }
                }
                else {
                    print(error)
                    getCompletionHandler(success: false, results: pin, error: error)
                }
            }
        }
    }

    func loadNewImages(pin: Pin, reloadCompletionHandler : (success: Bool, results: Pin, error: NSError?) -> Void) {
        
        let lat = Double(pin.latitude!)
        let lon = Double(pin.longitude!)
        
        let page = Int(pin.imageSet!) + 1
        
        print("Adding additional (new) images from web service.")
        
        WSClient.sharedInstance().getImages(lat, longitude: lon, page: page) { (success, results, error) in
            
            if success {
                dispatch_async(Utils.GlobalMainQueue) {
                    
                    var imageDatas = pin.imageDatas?.allObjects as! [ImageData]
                    
                    // create image entities
                    for result in results!.urls {
                        
                        let imageData = self.createImageData(result)
                        
                        // check existing image data, if url is known
                        let filter = NSPredicate(format: "url == %@", result)
                        let filteredImages = pin.imageDatas?.filteredSetUsingPredicate(filter)
                        
                        // if there is no result, add image to set of images
                        if filteredImages?.count == 0 {
                            imageDatas.append(imageData)
                        }
                    }
                    
                    pin.imageDatas = NSSet(array: imageDatas)
                    pin.imageSet = page
                    
                    // if no more pages are available, reset counter (keep it simple)
                    if Int(pin.imageSet!) >= results?.pages {
                        pin.imageSet = 0
                    }
                    
                    self.saveContext() { (success, error) in
                        
                        if !success {
                            print(error)
                            reloadCompletionHandler(success: false, results: pin, error: error)
                        }
                    }
                    
                    // return with success
                    reloadCompletionHandler(success: true, results: pin, error: nil)
                }
            }
            else {
                print(error)
                reloadCompletionHandler(success: false, results: pin, error: error)
            }
        }
    }
    
    func loadImagesAfterPinMoved(pin: Pin, reloadCompletionHandler : (success: Bool, results: Pin, error: NSError?) -> Void) {
        
        let lat = Double(pin.latitude!)
        let lon = Double(pin.longitude!)
        
        let page = 1
        
        print("Loading image data from web service and checking against available images.")

        WSClient.sharedInstance().getImages(lat, longitude: lon, page: page) { (success, results, error) in
            
            if success {
                dispatch_async(Utils.GlobalMainQueue) {
                    
                    var imageDatas = [ImageData]()
                    
                    // create image entities
                    for result in results!.urls {
                        
                        // check existing image data, if url is known
                        let filter = NSPredicate(format: "url == %@", result)
                        let filteredImages = pin.imageDatas?.filteredSetUsingPredicate(filter)
                        
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
                                    print(error)
                                    reloadCompletionHandler(success: false, results: pin, error: error)
                                    return
                                }
                            }
                        }
                    }

                    pin.imageDatas = NSSet(array: imageDatas)
                    pin.imageSet = page
                    
                    // if no more pages are available, reset counter (keep it simple)
                    if Int(pin.imageSet!) >= results?.pages {
                        pin.imageSet = 0
                    }
                    
                    self.saveContext() { (success, error) in
                        
                        if !success {
                            print(error)
                            reloadCompletionHandler(success: false, results: pin, error: error)
                            return
                        }
                    }
                    
                    // return with success
                    reloadCompletionHandler(success: true, results: pin, error: nil)
                }
            }
            else {
                print(error)
                reloadCompletionHandler(success: false, results: pin, error: error)
            }
        }
    }

    
    //# MARK: - Shared Instance
    class func sharedInstance() -> DataStore {
        
        struct Singleton {
            static var sharedInstance = DataStore()
        }
        return Singleton.sharedInstance
    }
}
