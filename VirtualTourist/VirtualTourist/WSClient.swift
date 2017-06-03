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
    var session = URLSession.shared
    var sessionID: String? = nil

    
    //# MARK: Data Access
    func getImages(_ latitude: Double, longitude: Double, page: Int, completionHandlerForGet: @escaping (_ success: Bool, _ results: FlickrData?, _ error: NSError?) -> Void) {
        
        getDataAccessGetResults(latitude: latitude, longitude: longitude, page: page, perPage: WSClient.FlickrParameterValues.PerPage) { (success, results, error) in
            
            if success {
                guard let resultList = results![FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    let userInfo = [NSLocalizedDescriptionKey : "Parameter '\(FlickrResponseKeys.Photos)' not found in get-results."]
                    print(userInfo)
                    
                    completionHandlerForGet(false, nil, NSError(domain: "getImages", code: 1, userInfo: userInfo))
                    return
                }
                
                guard let photos = resultList[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    let userInfo = [NSLocalizedDescriptionKey : "Parameter '\(FlickrResponseKeys.Photo)' not found in get-results."]
                    print(userInfo)
                    
                    completionHandlerForGet(false, nil, NSError(domain: "getImages", code: 1, userInfo: userInfo))
                    return
                }
                
                guard let pages = resultList[WSClient.FlickrResponseKeys.Pages] as? Int else {
                    let userInfo = [NSLocalizedDescriptionKey : "Parameter '\(FlickrResponseKeys.Pages)' not found in get-results."]
                    print(userInfo)
                    
                    completionHandlerForGet(false, nil, NSError(domain: "getImages", code: 1, userInfo: userInfo))
                    return
                }
                
                var urls = [String]()
                
                for photo in photos {
                    if let url = photo[WSClient.FlickrResponseKeys.MediumURL] as? String {
                        urls.append(url)
                    }
                }
                
                let flickrData = FlickrData(urls: urls, pages: pages)
                
                completionHandlerForGet(true, flickrData, nil)
            }
            else {
                print(error ?? "An error occured.")
                completionHandlerForGet(false, nil, error)
            }
        }
    }

    
    //# MARK: - URL Request Data Tasks Prep & Call
    fileprivate func getDataAccessGetResults(latitude: Double, longitude: Double, page: Int, perPage: Int, completionHandlerForGetResults: @escaping (_ success: Bool, _ results: [String:AnyObject]?, _ error: NSError?) -> Void) {
        
        // specify parameters
        let parameters: [String:AnyObject] = [
            WSClient.FlickrParameterKeys.Method: WSClient.FlickrParameterValues.SearchMethod as AnyObject,
            WSClient.FlickrParameterKeys.APIKey: WSClient.FlickrParameterValues.APIKey as AnyObject,
            WSClient.FlickrParameterKeys.Latitude: latitude as AnyObject,
            WSClient.FlickrParameterKeys.Longitude: longitude as AnyObject,
            WSClient.FlickrParameterKeys.Page: page as AnyObject,
            WSClient.FlickrParameterKeys.PerPage: perPage as AnyObject,
            WSClient.FlickrParameterKeys.SafeSearch: WSClient.FlickrParameterValues.UseSafeSearch as AnyObject,
            WSClient.FlickrParameterKeys.Extras: WSClient.FlickrParameterValues.MediumURL as AnyObject,
            WSClient.FlickrParameterKeys.Format: WSClient.FlickrParameterValues.ResponseFormat as AnyObject,
            WSClient.FlickrParameterKeys.NoJSONCallback: WSClient.FlickrParameterValues.DisableJSONCallback as AnyObject
        ]

        // make the request
        _ = taskForGETMethod("", parameters: parameters) { (results, error) in
            
            // check for errors and call the completion handler
            if let error = error {
                
                print(error)
                completionHandlerForGetResults(false, nil, error)
            }
            else {
                if let results = results as? [String:AnyObject] {
                    
                    completionHandlerForGetResults(true, results, nil)
                }
                else {
                    let userInfo = [NSLocalizedDescriptionKey : WSClient.ErrorMessage.HttpDataTaskFailed]
                    
                    completionHandlerForGetResults(false, nil, NSError(domain: "getDataAccessGetResults", code: 2, userInfo: userInfo))
                }
            }
        }
    }
    
    //# MARK: - URL Request Data Tasks
    fileprivate func taskForGETMethod(_ method: String, parameters: [String:AnyObject], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        //  build the URL, Configure the request
        let request = URLRequest(url: otmAuthURLFromParameters(parameters, withPathExtension: method))
        
        print("request: \(request)")
        
        // make the request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func sendError(_ error: Error?, localError: String) {
                
                print(error ?? "", localError)
                let userInfo = [NSLocalizedDescriptionKey : localError]
                
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            // check for errors
            if let error = error {
                
                if error._code == NSURLErrorTimedOut {
                    sendError(error, localError: WSClient.ErrorMessage.NetworkTimeout)
                    return
                }
            }
            
            guard (error == nil) else {
                sendError(error, localError: WSClient.ErrorMessage.GeneralHttpRequestError + "\(String(describing: error?.localizedDescription != nil ? error?.localizedDescription : "[No description]"))")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
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
    fileprivate func otmAuthURLFromParameters(_ parameters: [String:AnyObject], withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = WSClient.AuthConstants.ApiScheme
        components.host = WSClient.AuthConstants.ApiHost
        components.path = WSClient.AuthConstants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }

    
    //# MARK: JSON conversion
    func convertDataWithCompletionHandler(_ data: Data, offset: Int, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: Any!
        do {
            let newData = data.subdata(in: offset ..< data.count - offset)
            parsedResult = try JSONSerialization.jsonObject(with: newData, options: .allowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : WSClient.ErrorMessage.JsonParseError + "\(data)"]
            
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult as AnyObject, nil)
    }
    
    //# Shared Instance
    class func sharedInstance() -> WSClient {
        
        struct Singleton {
            static let sharedInstance = WSClient()
        }
        return Singleton.sharedInstance
    }
}
