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
    @IBOutlet weak var noImagesTextField: UITextField!

    
    //# MARK: Attributes
    let regionRadius: CLLocationDistance = 1000
    var isMapInitialized = false
    var isCreatingImages = false
    
    var pin: Pin!
    var imageDatas = [ImageData]()
    var images = [String:UIImage]()
    
    var touchedCell: (cell: UICollectionViewCell, indexPath: NSIndexPath)?
    
    
    //# MARK: Overrides
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        noImagesTextField.hidden = true
        
        initializeCollectionView()
        initializeForceTouch()
        initializeButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        showPinOnMap(pin)
        setCurrentLocation(pin)
        loadImages(pin)
    }
    
    
    //# MARK: Actions
    @IBAction func loadNewImages(sender: AnyObject) {
        
        noImagesTextField.hidden = true
        reloadButton.enabled = false
        
        DataStore.sharedInstance().loadNewImages(pin) { (success, results, error) in
            
            let resultsCount = results.imageDatas?.count
            
            if success {
                if resultsCount > 0 {
                    
                    dispatch_async(Utils.GlobalMainQueue) {
                        
                        for mo in results.imageDatas! {
                            let id = mo as! ImageData
                            
                            if Constants.AddImagesWithoutDeletion {
                                if !self.imageDatas.contains(id) {
                                    
                                    self.imageDatas.append(id)
                                    self.images[id.url!] = nil
                                }
                            }
                            else {
                                self.imageDatas = results.imageDatas?.allObjects as! [ImageData]
                                self.images = self.createEmptyImageDictionary(self.imageDatas)
                                self.photoAlbumCollectionView.reloadData()
                                
                                self.createUIImages()
                            }
                        }
                        
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
    
    //# MARK: - Initialize
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
        else {
            let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler))
            photoAlbumCollectionView.addGestureRecognizer(longPressGestureRecognizer)
        }
    }
    
    private func initializeButton() {
        
        if Constants.AddImagesWithoutDeletion {
            reloadButton.setTitle(Constants.AddNewImagesText, forState: .Normal)
        }
        else {
            reloadButton.setTitle(Constants.LoadNewImagesText, forState: .Normal)
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
    private func createEmptyImageDictionary(imageDatas: [ImageData]) -> [String:UIImage] {
        
        var images = [String:UIImage]()
        
        if imageDatas.count > 0 {
            
            for imageData in imageDatas {
                images[imageData.url!] = nil
            }
        }
        
        return images
    }
    
    private func loadImages(pin: Pin) {
        
        noImagesTextField.hidden = true
        
        DataStore.sharedInstance().getImages(pin) { (success, results, error) in
            
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
        
        dispatch_async(Utils.GlobalBackgroundQueue) {
            
            let downloadGroup = dispatch_group_create()
            
            for imageData in self.imageDatas {
                
                var photo_url: String = ""
                var noImage: Bool = false
                var imgDataImage: NSData?
                
                dispatch_sync(Utils.GlobalMainQueue) {
                    photo_url = imageData.url!
                    imgDataImage = imageData.image
                    noImage = imageData.image == nil
                }
                
                dispatch_group_enter(downloadGroup)
                
                if noImage {
                    
                    if let url = NSURL(string: photo_url) {
                        if let data = NSData(contentsOfURL: url) {
                            imgDataImage = data
                        }
                    }
                }
                
                if let imgDataImage = imgDataImage {
                    if let img = UIImage(data: imgDataImage) {
                        
                        self.images[photo_url] = img
                    }
                    else {
                        self.images[photo_url] = UIImage(named: "imageNotFound")
                    }
                }
                else {
                    self.images[photo_url] = UIImage(named: "imageNotFound")
                }
                
                dispatch_async(Utils.GlobalMainQueue) {
                    
                    imageData.image = imgDataImage
                    self.photoAlbumCollectionView.reloadData()
                }
                
                dispatch_group_leave(downloadGroup)
            }
            
            dispatch_group_wait(downloadGroup, DISPATCH_TIME_FOREVER)
            dispatch_async(Utils.GlobalMainQueue) {
                
                self.reloadButton.enabled = true
                self.isCreatingImages = false
            }
            
            DataStore.sharedInstance().saveContext() { (success, error) in
                
                if !success {
                    print(error)
                    Utils.showAlert(self, alertMessage: "An error occured while saving the images to the data base.", completion: nil)
                }
            }
            
            if Constants.ScrollToBottom {
                
                let itemIndex = self.collectionView(self.photoAlbumCollectionView, numberOfItemsInSection: 0) - 1
                let lastItemIndex = NSIndexPath(forItem: itemIndex, inSection: 0)
                self.photoAlbumCollectionView.scrollToItemAtIndexPath(lastItemIndex, atScrollPosition: .Bottom, animated: true)
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
        if imageData.image == nil {
            cell.activityIndicator.hidden = false
        }
        else {
            cell.imageView.image = images[imageData.url!]
            cell.activityIndicator.hidden = true
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath)
    {
        touchedCell = (cell: self.collectionView(photoAlbumCollectionView, cellForItemAtIndexPath: indexPath), indexPath: indexPath)
    }
    
    
    //# MARK: - UIViewControllerPreviewingDelegate
    //          Can only be used with devices that support force touch
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let cell = touchedCell?.cell else { return nil }
        guard let photoDetailViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoDetailViewController") as? PhotoDetailViewController else { return nil }
        
        let imageData = imageDatas[touchedCell!.indexPath.row]
        let image = images[imageData.url!]
        photoDetailViewController.image = image
        
        photoDetailViewController.preferredContentSize = CGSize(width: 0.0, height: 500)
        previewingContext.sourceRect = cell.frame
        
        return photoDetailViewController
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
        showViewController(viewControllerToCommit, sender: self)
    }
    
    func longPressHandler(recognizer: UILongPressGestureRecognizer)
    {
        guard let touchedCell = touchedCell
            where recognizer.state == UIGestureRecognizerState.Began else {
                return
        }
        
        guard let photoDetailViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoDetailViewController") as? PhotoDetailViewController else { return }
        
        let imageData = imageDatas[(touchedCell.indexPath.row)]
        let image = images[imageData.url!]
        photoDetailViewController.image = image
        
        showViewController(photoDetailViewController, sender: self)
    }
}
