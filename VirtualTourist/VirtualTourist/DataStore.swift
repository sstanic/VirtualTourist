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
            try stack.context.save()
        }
        catch {
            print("error :-o") //TODO: Add completion handler
        }
    }
    
    func loadPins() {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest()
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entityForName("Pin", inManagedObjectContext: self.stack.context)
        
        // Configure Fetch Request
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
    func getImages(pin: Pin, loadCompletionHandler : (success: Bool, results: Pin, error: NSError?) -> Void) {
        
        let lat = Double(pin.latitude!)
        let lon = Double(pin.longitude!)
        
        if pin.imageData?.count > 0 {
            print("Using locally saved image data.")
            loadCompletionHandler(success: true, results: pin, error: nil)
        }
        else {
        
            print("Loading image data from flickr.")
            
            self.notifyLoadingData(true)
            
            WSClient.sharedInstance().getImages(lat, longitude: lon) { (success, results, error) in
                
                var imageDataList = [ImageData]()
                
                if success {
                    self.notifyLoadingData(false)
                    
                    // create image entities
                    for result in results! {
                        let imageData = self.createImageData(result)
                        imageDataList.append(imageData)
                    }
                    
                    pin.imageData = NSSet(array: imageDataList)
                    do {
                        try self.stack.context.save()
                    }
                    catch {
                        // TODO: do something with the error
                    }
                    
                    // return with success
                    loadCompletionHandler(success: true, results: pin, error: nil)
                }
                else {
                    self.notifyLoadingData(false)
                    loadCompletionHandler(success: false, results: pin, error: error)
                }
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
