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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        initializeMap()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }

    private func initializeMap() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(showPhotoAlbum))
        gestureRecognizer.minimumPressDuration = 1.0
        
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func showPhotoAlbum(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .Began {
            let photoAlbumViewController = self.storyboard!.instantiateViewControllerWithIdentifier("photoAlbumViewController") as! PhotoAlbumViewController
            
            navigationController?.pushViewController(photoAlbumViewController, animated: true)
        }
    }
}
