//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 06.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func checkIfFirstLaunch() {
        if NSUserDefaults.standardUserDefaults().boolForKey(Constants.HasLaunchedBefore) {
            print("App has launched before.")
        }
        else {
            print("First launch. Set default values in NSUserDefaults.")
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: Constants.HasLaunchedBefore)
            NSUserDefaults.standardUserDefaults().setDouble(37.773972, forKey: Constants.MapLatitude)
            NSUserDefaults.standardUserDefaults().setDouble(-122.431297, forKey: Constants.MapLongitude)
            NSUserDefaults.standardUserDefaults().setDouble(2.8, forKey: Constants.MapLatitudeDelta)
            NSUserDefaults.standardUserDefaults().setDouble(2.1, forKey: Constants.MapLongitudeDelta)
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        checkIfFirstLaunch()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        saveContext()
    }

    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = DataStore.sharedInstance().stack.context
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}

