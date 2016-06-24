//
//  DataStore.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 10.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation
import CoreData

class DataStore: NSObject {
    
    //# MARK: Attributes
    let stack = CoreDataStack(modelName: "VirtualTourist")!
    
    dynamic var isLoading = false
    
    var isNotLoading: Bool {
        
        return !isLoading
    }
    
    var pins = [Pin]()
    
    private let concurrentDataQueue = dispatch_queue_create("com.savvista.udacity.VirtualTourist.dataQueue", DISPATCH_QUEUE_CONCURRENT)
    
    
    //# MARK: Data Model
    func createPin(latitude: Double, longitude: Double, title: String) -> Pin {
        
        let pin = Pin(latitude: latitude, longitude: longitude, title: title, context: stack.context)
        return pin
    }
    
    func createImageData(url: String) -> ImageData {
        
        let imageData = ImageData(url: url, context: stack.context)
        return imageData
    }
    
    func deleteImageData(imageData: ImageData) {
        
        stack.context.deleteObject(imageData)

        do {
            try self.stack.context.save()
        }
        catch {
            print("error :-o") //TODO: Add completion handler
        }
    }
    
    func saveContext() {
        if stack.context.hasChanges {
            do {
                try self.stack.context.save()
            }
            catch {
                print("error :-o") //TODO: Add completion handler
            }
        }
    }
    
    func loadPins() {

        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Pin", inManagedObjectContext: self.stack.context)
        fetchRequest.entity = entityDescription
        
        do {
            let result = try self.stack.context.executeFetchRequest(fetchRequest)
            self.pins = result as! [Pin]
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
    
    
    //# MARK: Get Images
    func getImages(pin: Pin, getCompletionHandler : (success: Bool, results: Pin, error: NSError?) -> Void) {
        
        let lat = Double(pin.latitude!)
        let lon = Double(pin.longitude!)
        
        if pin.imageDatas?.count > 0 {
            print("Using locally saved image data.")
            getCompletionHandler(success: true, results: pin, error: nil)
        }
        else {
        
            print("Loading image data from flickr.")
            
            self.notifyLoadingData(true)
            
            WSClient.sharedInstance().getImages(lat, longitude: lon) { (success, results, error) in
                
                self.notifyLoadingData(false)
                var imageDatas = [ImageData]()
                
                if success {
                    
                    // create image entities
                    for result in results! {
                        let imageData = self.createImageData(result)
                        imageDatas.append(imageData)
                    }
                    
                    pin.imageDatas = NSSet(array: imageDatas)

                    do {
                        try self.stack.context.save()
                    }
                    catch {
                        // TODO: do something with the error
                    }
                    
                    // return with success
                    getCompletionHandler(success: true, results: pin, error: nil)
                }
                else {
                    self.notifyLoadingData(false)
                    getCompletionHandler(success: false, results: pin, error: error)
                }
            }
        }
    }

    func reloadImages(pin: Pin, reloadCompletionHandler : (success: Bool, results: Pin, error: NSError?) -> Void) {
        
        let lat = Double(pin.latitude!)
        let lon = Double(pin.longitude!)
        
        print("Reloading image data from flickr.")
        
        self.notifyLoadingData(true)
        
        WSClient.sharedInstance().getImages(lat, longitude: lon) { (success, results, error) in
            
            self.notifyLoadingData(false)
            var imageDatas = [ImageData]()
            
            if success {
                
                // create image entities
                for result in results! {
                    
                    let imageData = self.createImageData(result)
                    
                    // check existing image data, if url is known
                    let filter = NSPredicate(format: "url == %@", result)
                    let filteredImages = pin.imageDatas?.filteredSetUsingPredicate(filter)
                    
                    // if there is a result, use the local image
                    if filteredImages?.count > 0 {
                        let filteredImageData = filteredImages?.first as? ImageData
                        imageData.image = filteredImageData?.image
                        
                        print("found url in local image data: \(result)")
                    }
                    else {
                        print("url not found in local image data: \(result)")
                    }
                    
                    imageDatas.append(imageData)
                }
                
                pin.imageDatas = NSSet(array: imageDatas)
                
                do {
                    try self.stack.context.save()
                }
                catch {
                    // TODO: do something with the error
                }
                
                // return with success
                reloadCompletionHandler(success: true, results: pin, error: nil)
            }
            else {
                self.notifyLoadingData(false)
                reloadCompletionHandler(success: false, results: pin, error: error)
            }
        }
    }
    
    //# MARK: Notifications
    private func notifyLoadingData(isLoading: Bool) {
        dispatch_async(Utils.GlobalMainQueue) {
            self.isLoading = isLoading
        }
    }
    
    //# MARK: Shared Instance
    class func sharedInstance() -> DataStore {
        
        struct Singleton {
            static var sharedInstance = DataStore()
        }
        return Singleton.sharedInstance
    }
}
