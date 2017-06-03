//
//  Utils.swift
//
//  Created by Sascha Stanic on 06.05.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation
import UIKit

class Utils {
    
    //# MARK: Queuing
    static var GlobalMainQueue: DispatchQueue {
        return DispatchQueue.main
    }
    
    static var GlobalUserInteractiveQueue: DispatchQueue {
        return DispatchQueue.global(qos: .userInteractive)
    }
    
    static var GlobalUserInitiatedQueue: DispatchQueue {
        return DispatchQueue.global(qos: .userInitiated)
    }
    
    static var GlobalUtilityQueue: DispatchQueue {
        return DispatchQueue.global(qos: .utility)
    }
    
    static var GlobalBackgroundQueue: DispatchQueue {
        return DispatchQueue.global(qos: .background)
    }
    
    
    //# MARK: Alert
    static func showAlert(_ viewController: UIViewController, alertMessage: String, completion: (() -> Void)?) {
        
        Utils.GlobalMainQueue.async {
            
            let alertController = UIAlertController(title: "Info", message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
            let action = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                if let c = completion {
                    c()
                }
            }
            alertController.addAction(action)
            
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    //# MARK: Activity Indicator
    static func showActivityIndicator(_ view: UIView, activityIndicator: UIActivityIndicatorView, alpha: CGFloat) {
        
        Utils.GlobalMainQueue.async {
            
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            
            for subview in view.subviews {
                subview.alpha = alpha
            }
            
            // do not 'hide' the activity indicator
            activityIndicator.alpha = 1.0
        }
    }
    
    static func hideActivityIndicator(_ view: UIView, activityIndicator: UIActivityIndicatorView) {
        
        Utils.GlobalMainQueue.async {
            
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            
            for subview in view.subviews {
                subview.alpha = 1.0
            }
        }
    }
}
