//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 06.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import UIKit
import MapKit
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
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.navigationController?.isNavigationBarHidden = false
    }

    
    //# MARK: - Initialize
    fileprivate func initializeMap() {
        
        mapView.delegate = self
        
        let gestureRecognizerLongPress = UILongPressGestureRecognizer(target: self, action: #selector(createNewPin))
        gestureRecognizerLongPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(gestureRecognizerLongPress)
        
        // init region
        let latitude = UserDefaults.standard.double(forKey: Constants.MapLatitude)
        let longitude = UserDefaults.standard.double(forKey: Constants.MapLongitude)
        let latitudeDelta = UserDefaults.standard.double(forKey: Constants.MapLatitudeDelta)
        let longitudeDelta = UserDefaults.standard.double(forKey: Constants.MapLongitudeDelta)
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let coordinateSpan = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        let region = MKCoordinateRegionMake(location, coordinateSpan)
        
        mapView.setRegion(region, animated: true)
    }
    
    fileprivate func initializePins() {
        
        DataStore.sharedInstance().loadPins() { (success, error) in
            
            if !success {
                print(error as Any)
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
    @objc func createNewPin(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        var touchPoint: CGPoint = gestureRecognizer.location(in: mapView)
        var touchMapCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        switch gestureRecognizer.state {
            
        case .began:
            newMapItem = MapItem(title: "<...>", location: touchMapCoordinate)
            mapView.addAnnotation(newMapItem!)
            
        case .ended:
            geocodeMapItem(newMapItem!) { (success, error) in
                
                if success {
                    let pin = DataStore.sharedInstance().createPin(touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, title: self.newMapItem!.title!)
                    self.newMapItem!.pin = pin
                    self.showImages(pin)
                }
                else {
                    print(error as Any)
                    Utils.showAlert(self, alertMessage: "An error occured while creating a new pin.", completion: nil)
                }
            }
            
        case .changed:
            touchPoint = gestureRecognizer.location(in: mapView)
            touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            mapView.removeAnnotation(newMapItem!)
            newMapItem = MapItem(title: ".", location: touchMapCoordinate)
            mapView.addAnnotation(newMapItem!)
            
        default:
            break
        }
    }
    
    fileprivate func showImages(_ pin: Pin) {
        
        let photoAlbumViewController = self.storyboard!.instantiateViewController(withIdentifier: "photoAlbumViewController") as! PhotoAlbumViewController
        photoAlbumViewController.pin = pin
        
        navigationController?.pushViewController(photoAlbumViewController, animated: true)
    }
    
    fileprivate func geocodeMapItem(_ mapItem: MapItem, geocodeCompletionHandler: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        var address = ""
        let location = CLLocation(latitude: mapItem.coordinate.latitude, longitude: mapItem.coordinate.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemark, error) in
            
            if error != nil {
                mapItem.title = "<unknown>"
                geocodeCompletionHandler(false, error! as NSError)
                return
            }
            else {
                if (placemark?.count > 0) {
                    for al in placemark?.first!.addressDictionary?["FormattedAddressLines"] as! NSArray {
                        if address == "" {
                            address = address + (al as! String)
                        }
                        else {
                            address = (address + " -- ") + (al as! String)
                        }
                    }
                }
            }
            
            mapItem.title = address
            
            geocodeCompletionHandler(true, nil)
        }
    }
    
    
    //# MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }

        let identifier = "pin"
        var view: MKPinAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            
            dequeuedView.annotation = annotation
            view = dequeuedView
        }
        else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            let btn = UIButton(type: .detailDisclosure)
            view.rightCalloutAccessoryView = btn as UIView
            view.isDraggable = true
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == MKAnnotationViewDragState.ending {
            
            if let mapItem = view.annotation as? MapItem {
                
                Utils.GlobalBackgroundQueue.async {
                    
                    self.geocodeMapItem(mapItem) { (success, error) in
                        
                        if success {
                            let pin = mapItem.pin
                            pin?.latitude = mapItem.coordinate.latitude as NSNumber
                            pin?.longitude = mapItem.coordinate.longitude as NSNumber
                            
                            pin?.title = mapItem.title
                            pin?.imageSet = 1
                            DataStore.sharedInstance().loadImagesAfterPinMoved(pin!) { (success, results, error) in
                                
                                if !success {
                                    print(error as Any)
                                    Utils.showAlert(self, alertMessage: "An error occured while trying to load new images.", completion: nil)
                                }
                            }
                        }
                        else {
                            print(error as Any)
                            Utils.showAlert(self, alertMessage: "An error occured while dragging the map pin.", completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: Constants.MapLatitude)
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: Constants.MapLongitude)
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: Constants.MapLatitudeDelta)
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: Constants.MapLongitudeDelta)
    }
}
