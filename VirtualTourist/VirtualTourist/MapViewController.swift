//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 06.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    //# MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    
    //# MARK: Attributes
    var newMapItem: MapItem?
    
    
    //# MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeMap()
        initializePins()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        self.navigationController?.navigationBarHidden = false
    }

    
    //# MARK: - Initialize
    private func initializeMap() {
        
        mapView.delegate = self
        
        let gestureRecognizerLongPress = UILongPressGestureRecognizer(target: self, action: #selector(createNewPin))
        gestureRecognizerLongPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(gestureRecognizerLongPress)
        
        // init region
        let latitude = NSUserDefaults.standardUserDefaults().doubleForKey(Constants.MapLatitude)
        let longitude = NSUserDefaults.standardUserDefaults().doubleForKey(Constants.MapLongitude)
        let latitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey(Constants.MapLatitudeDelta)
        let longitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey(Constants.MapLongitudeDelta)
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let coordinateSpan = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        let region = MKCoordinateRegionMake(location, coordinateSpan)
        
        mapView.setRegion(region, animated: true)
    }
    
    private func initializePins() {
        
        DataStore.sharedInstance().loadPins() { (success, error) in
            
            if !success {
                print(error)
                Utils.showAlert(self, alertMessage: "An error occured while loading map data from the data base.", completion: nil)
            }
        }
        
        for pin in DataStore.sharedInstance().pins {
            
            let location = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
            let mapItem = MapItem(title: pin.title!, location: location)
            mapItem.pin = pin
            mapView.addAnnotation(mapItem)
        }
    }
    
    
    //# MARK: - Pin, Image, Geocode
    @objc func createNewPin(gestureRecognizer: UILongPressGestureRecognizer) {
        
        var touchPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        var touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        switch gestureRecognizer.state {
            
        case .Began:
            newMapItem = MapItem(title: "<...>", location: touchMapCoordinate)
            mapView.addAnnotation(newMapItem!)
            
        case .Ended:
            geocodeMapItem(newMapItem!) { (success, error) in
                
                if success {
                    let pin = DataStore.sharedInstance().createPin(touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, title: self.newMapItem!.title!)
                    self.newMapItem!.pin = pin
                    self.showImages(pin)
                }
                else {
                    print(error)
                    Utils.showAlert(self, alertMessage: "An error occured while creating a new pin.", completion: nil)
                }
            }
            
        case .Changed:
            touchPoint = gestureRecognizer.locationInView(mapView)
            touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            mapView.removeAnnotation(newMapItem!)
            newMapItem = MapItem(title: ".", location: touchMapCoordinate)
            mapView.addAnnotation(newMapItem!)
            
        default:
            break
        }
    }
    
    private func showImages(pin: Pin) {
        
        let photoAlbumViewController = self.storyboard!.instantiateViewControllerWithIdentifier("photoAlbumViewController") as! PhotoAlbumViewController
        photoAlbumViewController.pin = pin
        
        navigationController?.pushViewController(photoAlbumViewController, animated: true)
    }
    
    private func geocodeMapItem(mapItem: MapItem, geocodeCompletionHandler: (success: Bool, error: NSError?) -> Void) {
        
        var address = ""
        let location = CLLocation(latitude: mapItem.coordinate.latitude, longitude: mapItem.coordinate.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemark, error) in
            
            if error != nil {
                mapItem.title = "<unknown>"
                geocodeCompletionHandler(success: false, error: error)
                return
            }
            else {
                if (placemark?.count > 0) {
                    for al in placemark?.first!.addressDictionary?["FormattedAddressLines"] as! NSArray {
                        if address == "" {
                            address = address.stringByAppendingString(al as! String)
                        }
                        else {
                            address = address.stringByAppendingString(" -- ").stringByAppendingString(al as! String)
                        }
                    }
                }
            }
            
            mapItem.title = address
            
            geocodeCompletionHandler(success: true, error: nil)
        }
    }
    
    
    //# MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }

        let identifier = "pin"
        var view: MKPinAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
            
            dequeuedView.annotation = annotation
            view = dequeuedView
        }
        else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            let btn = UIButton(type: .DetailDisclosure)
            view.rightCalloutAccessoryView = btn as UIView
            view.draggable = true
        }
        
        return view
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == view.rightCalloutAccessoryView {
            
            if let mapItem = view.annotation as? MapItem {
                
                if let pin = mapItem.pin {
                    showImages(pin)
                }
            }
        }
    }
    
    //Remark: Removed navigation on click to be able to drag and drop the pin
//    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
//        if let mapItem = view.annotation as? MapItem {
//            if let pin = mapItem.pin {
//                showImages(pin)
//            }
//        }
//    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == MKAnnotationViewDragState.Ending {
            
            if let mapItem = view.annotation as? MapItem {
                
                dispatch_async(Utils.GlobalBackgroundQueue) {
                    
                    self.geocodeMapItem(mapItem) { (success, error) in
                        
                        if success {
                            let pin = mapItem.pin
                            pin?.latitude = mapItem.coordinate.latitude
                            pin?.longitude = mapItem.coordinate.longitude
                            
                            pin?.title = mapItem.title
                            pin?.imageSet = 1
                            DataStore.sharedInstance().loadImagesAfterPinMoved(pin!) { (success, results, error) in
                                
                                if !success {
                                    print(error)
                                    Utils.showAlert(self, alertMessage: "An error occured while trying to load new images.", completion: nil)
                                }
                            }
                        }
                        else {
                            print(error)
                            Utils.showAlert(self, alertMessage: "An error occured while dragging the map pin.", completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.latitude, forKey: Constants.MapLatitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.longitude, forKey: Constants.MapLongitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: Constants.MapLatitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: Constants.MapLongitudeDelta)
    }
}
