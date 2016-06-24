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
    
    @IBOutlet weak var mapView: MKMapView!

    var mapItem: MapItem?
    
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

    private func initializeMap() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(createNewPin))
        gestureRecognizer.minimumPressDuration = 0.5
        
        mapView.addGestureRecognizer(gestureRecognizer)
        mapView.delegate = self
        
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
        
        DataStore.sharedInstance().loadPins()
        
        for pin in DataStore.sharedInstance().pins {
            let location = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
            let mapItem = MapItem(title: pin.title!, subtitle: "", location: location)
            mapItem.pin = pin
            mapView.addAnnotation(mapItem)
        }
    }
    
    @objc func createNewPin(gestureRecognizer: UILongPressGestureRecognizer) {
        
        var touchPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        var touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        switch gestureRecognizer.state {
            
        case .Began:
            mapItem = MapItem(title: "<...>", subtitle: "", location: touchMapCoordinate)
            mapView.addAnnotation(mapItem!)
            
        case .Ended:
            geocodeMapItem(mapItem!) { (success, error) in
                
                let pin = DataStore.sharedInstance().createPin(touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, title: self.mapItem!.title!)
                self.mapItem!.pin = pin
                self.showImages(pin)
                DataStore.sharedInstance().pins.append(pin)
            }
            
        case .Changed:
            touchPoint = gestureRecognizer.locationInView(mapView)
            touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            mapView.removeAnnotation(mapItem!)
            mapItem = MapItem(title: ".", subtitle: "", location: touchMapCoordinate)
            mapView.addAnnotation(mapItem!)
            
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
                address = "<unknown>"
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
        
        if let annotation = annotation as? MapItem {
            let identifier = "pin"
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
                
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                let btn = UIButton(type: .DetailDisclosure)
                view.rightCalloutAccessoryView = btn as UIView
            }
            return view
        }
        return nil
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
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.latitude, forKey: Constants.MapLatitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.longitude, forKey: Constants.MapLongitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: Constants.MapLatitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: Constants.MapLongitudeDelta)

    }
}
