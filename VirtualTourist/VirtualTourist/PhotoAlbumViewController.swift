//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 07.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoAlbumCollectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var reloadButton: UIButton!
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noImagesTextField: UITextField!

    let regionRadius: CLLocationDistance = 1000
    var isMapInitialized = false
    
    var pin: Pin!
    var imageDatas = [ImageData]()
    var images = [String:UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noImagesTextField.hidden = true
        initializeCollectionView()
    }
    
    override func viewDidAppear(animated: Bool) {
        showPinOnMap(pin)
        setCurrentLocation(pin)
        
        loadImages(pin)
    }
    
    private func initializeCollectionView() {
        // remove space on top of collection view
        self.automaticallyAdjustsScrollViewInsets = false;
        
        photoAlbumCollectionView.delegate = self
        photoAlbumCollectionView.dataSource = self
        
        // set dimension of collection items
        // need to divide by n+1 to get n items on the screen in portrait orientation
        let space: CGFloat = 2.0
        let nrOfItems: CGFloat = 4.0
        
        // (simple) check for orientation to set the correct size
        var dimension: CGFloat!
        if (view.frame.size.width < view.frame.size.height) {
            dimension = (view.frame.size.width - (2 * space)) / nrOfItems
        }
        else {
            dimension = (view.frame.size.height - (2 * space)) / nrOfItems
        }
        
        collectionViewFlowLayout.minimumInteritemSpacing = space
        collectionViewFlowLayout.minimumLineSpacing = space
        collectionViewFlowLayout.itemSize = CGSizeMake(dimension, dimension)
    }
    
    private func showPinOnMap(pin: Pin) {
        
        let location = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
        let mapItem = MapItem(title: pin.title!, subtitle: "", location: location)
        mapView.addAnnotation(mapItem)
    }
    
    private func setCurrentLocation(pin: Pin) {
        
        let coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    private func createEmptyImageDictionary(imageDataList: [ImageData]) -> [String:UIImage] {
        var images = [String:UIImage]()
        
        if imageDataList.count > 0 {
            for imageData in imageDataList {
                let image = UIImage(named: "placeholder")
                images[imageData.url!] = image
            }
        }
        
        return images
    }
    
    private func loadImages(pin: Pin) {
        
        noImagesTextField.hidden = true
        
        Utils.showActivityIndicator(self.view, activityIndicator: activityIndicator)
        
        DataStore.sharedInstance().getImages(pin) { (success, results, error) in
            
            Utils.hideActivityIndicator(self.view, activityIndicator: self.activityIndicator)
            
            let resultsCount = results.imageData?.count
            
            if success {
                if resultsCount > 0 {
                    
                    dispatch_async(Utils.GlobalMainQueue) {
                        
                        self.imageDatas = results.imageData?.allObjects as! [ImageData]
                        self.images = self.createEmptyImageDictionary(self.imageDatas)
                        
                        self.photoAlbumCollectionView.reloadData()
                        
                        self.loadImages()
                    }
                }
                else {
                    
                    dispatch_async(Utils.GlobalMainQueue) {
                        self.noImagesTextField.hidden = false
                    }
                }
            }
            else {
                // TODO: some problem occured
            }
        }
    }
    
    private func loadImages() {
        
        reloadButton.enabled = false
        photoAlbumCollectionView.alpha = 0.5
        
        dispatch_async(Utils.GlobalBackgroundQueue) {
            
            let downloadGroup = dispatch_group_create()
            
            for imageData in self.imageDatas {
                
                let photo_url = imageData.url!
                
                dispatch_group_enter(downloadGroup)
                
                if imageData.image == nil {
                    if let url = NSURL(string: photo_url) {
                        
                        if let data = NSData(contentsOfURL: url) {
                            let img = UIImage(data: data)
                            
                            if let image = img {
                                self.images[photo_url] = image
                                self.addImageToImageData(image, imageData: imageData)
                            }
                        }
                    }
                }
                else {
                    self.images[photo_url] = UIImage(data: imageData.image!)
                }
                
                dispatch_group_leave(downloadGroup)
                
                dispatch_async(Utils.GlobalMainQueue) {
                    self.photoAlbumCollectionView.reloadData()
                }
            }
            
            dispatch_group_wait(downloadGroup, DISPATCH_TIME_FOREVER)
            dispatch_async(Utils.GlobalMainQueue) {
                self.reloadButton.enabled = true
                self.photoAlbumCollectionView.alpha = 1.0
            }
            
            DataStore.sharedInstance().saveContext()
        }
    }
    
    private func addImageToImageData(image: UIImage, imageData: ImageData) {
        let url = imageData.url!
        
        if url.hasSuffix("jpg") {
            imageData.image = UIImageJPEGRepresentation(image, 1.0)
            return
        }
        
        if url.hasSuffix("png") {
            imageData.image = UIImagePNGRepresentation(image)
            return
        }
        
        imageData.image = nil
        print("imagetype unknown for url <\(url)>")
    }
    
    @IBAction func reloadImages(sender: AnyObject) {
    }
    
    private func deleteImage(index: Int) {
        
        let imageData = imageDatas[index]
        images.removeValueForKey(imageData.url!)
        imageDatas.removeAtIndex(index)
        
        DataStore.sharedInstance().deleteImageData(imageData)
    }
    
    //#MARK: - UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        deleteImage(indexPath.row)
        collectionView.deleteItemsAtIndexPaths([indexPath])
    }
    
    
    //#MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageDatas.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        
        let imageData = imageDatas[indexPath.row]
        cell.imageView.image = images[imageData.url!]
        
        return cell
    }
}
