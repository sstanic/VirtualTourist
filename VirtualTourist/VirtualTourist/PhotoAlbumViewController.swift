//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 07.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIViewControllerPreviewingDelegate {
    
    //# MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoAlbumCollectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noImagesTextField: UITextField!

    
    //# MARK: Attributes
    let regionRadius: CLLocationDistance = 1000
    var isMapInitialized = false
    var isCreatingImages = false
    
    var pin: Pin!
    var imageDatas = [ImageData]()
    var images = [String:UIImage]()
    
    
    //# MARK: Overrides
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        noImagesTextField.hidden = true
        
        initializeCollectionView()
        initializeForceTouch()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        showPinOnMap(pin)
        setCurrentLocation(pin)
        loadImages(pin)
    }
    
    
    //# MARK: Actions
    @IBAction func reloadImages(sender: AnyObject) {
        
        noImagesTextField.hidden = true
        
        Utils.showActivityIndicator(self.view, activityIndicator: activityIndicator)
        
        DataStore.sharedInstance().reloadImages(pin) { (success, results, error) in
            
            Utils.hideActivityIndicator(self.view, activityIndicator: self.activityIndicator)
            
            let resultsCount = results.imageDatas?.count
            
            if success {
                if resultsCount > 0 {
                    
                    dispatch_async(Utils.GlobalMainQueue) {
                        
                        self.imageDatas = results.imageDatas?.allObjects as! [ImageData]
                        self.images = self.createEmptyImageDictionary(self.imageDatas)
                        
                        self.photoAlbumCollectionView.reloadData()
                        self.createUIImages()
                    }
                }
                else {
                    
                    dispatch_async(Utils.GlobalMainQueue) {
                        
                        self.noImagesTextField.hidden = false
                    }
                }
            }
            else {
                print(error)
                Utils.showAlert(self, alertMessage: "An error occured while reloading images.", completion: nil)
            }
        }
    }
    
    //# MARK: Initialize
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
    
    private func initializeForceTouch() {
        
        if traitCollection.forceTouchCapability == .Available {
            
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
    }
    
    
    //# MARK: Map
    private func showPinOnMap(pin: Pin) {
        
        let location = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
        let mapItem = MapItem(title: pin.title!, location: location)
        mapView.addAnnotation(mapItem)
    }
    
    private func setCurrentLocation(pin: Pin) {
        
        let coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    //# MARK: Images
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
            
            let resultsCount = results.imageDatas?.count
            
            if success {
                dispatch_async(Utils.GlobalMainQueue) {
                    
                    if resultsCount > 0 {
                        
                        self.imageDatas = results.imageDatas?.allObjects as! [ImageData]
                        self.images = self.createEmptyImageDictionary(self.imageDatas)
                        self.photoAlbumCollectionView.reloadData()
                        
                        self.createUIImages()
                    }
                    else {
                        self.noImagesTextField.hidden = false
                    }
                }
            }
            else {
                print(error)
                Utils.showAlert(self, alertMessage: "An error occured while loading images from flickr.", completion: nil)
            }
        }
    }
    
    private func createUIImages() {
        
        reloadButton.enabled = false
        isCreatingImages = true

        Utils.showActivityIndicator(self.view, activityIndicator: activityIndicator)
        
        dispatch_async(Utils.GlobalBackgroundQueue) {
            
            let downloadGroup = dispatch_group_create()
            
            for imageData in self.imageDatas {
                
                let photo_url = imageData.url!
                
                dispatch_group_enter(downloadGroup)
                
                if imageData.image == nil {
                    
                    if let url = NSURL(string: photo_url) {
                        if let data = NSData(contentsOfURL: url) {
                            
                            imageData.image = data
                            if let img = UIImage(data: data) {
                                self.images[photo_url] = img
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
                self.isCreatingImages = false
                
                Utils.hideActivityIndicator(self.view, activityIndicator: self.activityIndicator)
            }
            
            DataStore.sharedInstance().saveContext() { (success, error) in
                
                if !success {
                    print(error)
                    Utils.showAlert(self, alertMessage: "An error occured while saving the images to the data base.", completion: nil)
                }
            }
        }
    }
    
    private func deleteImage(index: Int) {
        
        let imageData = imageDatas[index]
        images.removeValueForKey(imageData.url!)
        imageDatas.removeAtIndex(index)
        
        if (images.count == 0) {
            noImagesTextField.hidden = false
        }
        
        DataStore.sharedInstance().deleteImageData(imageData) { (success, error) in
            
            if !success {
                print(error)
                Utils.showAlert(self, alertMessage: "An error occured while deleting the image.", completion: nil)
            }
        }
    }
    
    
    //# MARK: - UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        if isCreatingImages {
            Utils.showAlert(self, alertMessage: "Cannot delete images while loading. Please wait until all images are loaded.", completion: nil)
            return
        }
        
        deleteImage(indexPath.row)
        collectionView.deleteItemsAtIndexPaths([indexPath])
    }
    
    
    //# MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return imageDatas.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        
        let imageData = imageDatas[indexPath.row]
        cell.imageView.image = images[imageData.url!]
        
        return cell
    }
    
    
    //# MARK: UIViewControllerPreviewingDelegate
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let offset = photoAlbumCollectionView.frame.origin.y
        let contentOffset = photoAlbumCollectionView.contentOffset.y
        
        let tapLocation = CGPoint(x: location.x, y: location.y - offset + contentOffset)
        
        guard let indexPath = photoAlbumCollectionView?.indexPathForItemAtPoint(tapLocation) else { return nil }
        guard let cell = photoAlbumCollectionView?.cellForItemAtIndexPath(indexPath) else { return nil }
        guard let photoDetailViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoDetailViewController") as? PhotoDetailViewController else { return nil }
        
        let imageData = imageDatas[indexPath.row]
        let image = images[imageData.url!]
        photoDetailViewController.image = image
        
        photoDetailViewController.preferredContentSize = CGSize(width: 0.0, height: 500)
        previewingContext.sourceRect = cell.frame
        
        return photoDetailViewController
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
        showViewController(viewControllerToCommit, sender: self)
    }
}
