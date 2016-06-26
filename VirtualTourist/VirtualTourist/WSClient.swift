//
//  WSClient.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 09.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation
import UIKit

class WSClient {
    
    //# MARK: Attributes
    var session = NSURLSession.sharedSession()
    var sessionID: String? = nil

    
    //# MARK: Data Access
    func getImages(latitude: Double, longitude: Double, completionHandlerForGet: (success: Bool, results: [String]?, error: NSError?) -> Void) {
        
        getDataAccessGetResults(latitude: latitude, longitude: longitude, perPage: WSClient.FlickrParameterValues.PerPage) { (success, results, error) in
            
            if success {
                guard let resultList = results![FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    let userInfo = [NSLocalizedDescriptionKey : "Parameter '\(FlickrResponseKeys.Photos)' not found in get-results."]
                    print(userInfo)
                    
                    completionHandlerForGet(success: false, results: nil, error: NSError(domain: "getImages", code: 1, userInfo: userInfo))
                    return
                }
                
                guard let photos = resultList[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    let userInfo = [NSLocalizedDescriptionKey : "Parameter '\(FlickrResponseKeys.Photo)' not found in get-results."]
                    print(userInfo)
                    
                    completionHandlerForGet(success: false, results: nil, error: NSError(domain: "getImages", code: 1, userInfo: userInfo))
                    return
                }
                
                var urls = [String]()
                
                for photo in photos {
                    if let url = photo[WSClient.FlickrResponseKeys.MediumURL] as? String {
                        urls.append(url)
                    }
                }
                
                completionHandlerForGet(success: true, results: urls, error: nil)
            }
            else {
                print(error)
                completionHandlerForGet(success: false, results: nil, error: error)
            }
        }
    }

    
    //# MARK: - URL Request Data Tasks Prep & Call
    private func getDataAccessGetResults(latitude latitude: Double, longitude: Double, perPage: Int, completionHandlerForGetResults: (success: Bool, results: [String:AnyObject]?, error: NSError?) -> Void) {
        
        // specify parameters
        let parameters: [String:AnyObject] = [
            WSClient.FlickrParameterKeys.Method: WSClient.FlickrParameterValues.SearchMethod,
            WSClient.FlickrParameterKeys.APIKey: WSClient.FlickrParameterValues.APIKey,
            WSClient.FlickrParameterKeys.Latitude: latitude,
            WSClient.FlickrParameterKeys.Longitude: longitude,
            WSClient.FlickrParameterKeys.PerPage: perPage,
            
            WSClient.FlickrParameterKeys.SafeSearch: WSClient.FlickrParameterValues.UseSafeSearch,
            WSClient.FlickrParameterKeys.Extras: WSClient.FlickrParameterValues.MediumURL,
            WSClient.FlickrParameterKeys.Format: WSClient.FlickrParameterValues.ResponseFormat,
            WSClient.FlickrParameterKeys.NoJSONCallback: WSClient.FlickrParameterValues.DisableJSONCallback
        ]

        // make the request
        taskForGETMethod("", parameters: parameters) { (results, error) in
            
            // check for errors and call the completion handler
            if let error = error {
                
                print(error)
                completionHandlerForGetResults(success: false, results: nil, error: error)
                
            }
            else {
                if let results = results as? [String:AnyObject] {
                    
                    completionHandlerForGetResults(success: true, results: results, error: nil)
                }
                else {
                    let userInfo = [NSLocalizedDescriptionKey : WSClient.ErrorMessage.HttpDataTaskFailed]
                    
                    completionHandlerForGetResults(success: false, results: nil, error: NSError(domain: "getDataAccessGetResults", code: 2, userInfo: userInfo))
                }
            }
        }
    }
    
    //# MARK: - URL Request Data Tasks
    private func taskForGETMethod(method: String, parameters: [String:AnyObject], completionHandlerForGET: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        //  build the URL, Configure the request
        let request = NSMutableURLRequest(URL: otmAuthURLFromParameters(parameters, withPathExtension: method))
        
        print("request: \(request)")
        
        // make the request
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func sendError(error: NSError?, localError: String) {
                
                print(error, localError)
                let userInfo = [NSLocalizedDescriptionKey : localError]
                
                completionHandlerForGET(result: nil, error: NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            // check for errors
            if let error = error {
                
                if error.code == NSURLErrorTimedOut {
                    sendError(error, localError: WSClient.ErrorMessage.NetworkTimeout)
                    return
                }
            }
            
            guard (error == nil) else {
                sendError(error, localError: WSClient.ErrorMessage.GeneralHttpRequestError.stringByAppendingString("\(error?.localizedDescription != nil ? error?.localizedDescription : "[No description]")"))
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError(error, localError: WSClient.ErrorMessage.StatusCodeFailure)
                return
            }
            
            guard let data = data else {
                sendError(error, localError: WSClient.ErrorMessage.NoDataFoundInRequest)
                return
            }
            
            // parse the data and use the data (happens in completion handler)
            self.convertDataWithCompletionHandler(data, offset: 0, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        // start the request
        task.resume()
        
        return task
    }

    
    //# MARK: - URL Creation
    private func otmAuthURLFromParameters(parameters: [String:AnyObject], withPathExtension: String? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = WSClient.AuthConstants.ApiScheme
        components.host = WSClient.AuthConstants.ApiHost
        components.path = WSClient.AuthConstants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }

    
    //# MARK: JSON conversion
    func convertDataWithCompletionHandler(data: NSData, offset: Int, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            let newData = data.subdataWithRange(NSMakeRange(offset, data.length - offset))
            parsedResult = try NSJSONSerialization.JSONObjectWithData(newData, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : WSClient.ErrorMessage.JsonParseError.stringByAppendingString("\(data)")]
            
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }
    
    //# Shared Instance
    class func sharedInstance() -> WSClient {
        
        struct Singleton {
            static var sharedInstance = WSClient()
        }
        return Singleton.sharedInstance
    }
}