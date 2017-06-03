//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 07.06.16.
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
    
    
    //# MARK: Overrides
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        noImagesTextField.isHidden = true
        
        initializeCollectionView()
        initializeForceTouch()
        initializeButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        showPinOnMap(pin)
        setCurrentLocation(pin)
        loadImages(pin)
    }
    
    
    //# MARK: Actions
    @IBAction func loadNewImages(_ sender: AnyObject) {
        
        noImagesTextField.isHidden = true
        reloadButton.isEnabled = false
        
        DataStore.sharedInstance().loadNewImages(pin) { (success, results, error) in
            
            let resultsCount = results.imageDatas?.count
            
            if success {
                if resultsCount > 0 {
                    
                    Utils.GlobalMainQueue.async {
                        
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
                    Utils.GlobalMainQueue.async {
                        
                        self.noImagesTextField.isHidden = false
                    }
                }
            }
            else {
                print(error as Any)
                Utils.showAlert(self, alertMessage: "An error occured while reloading images.", completion: nil)
            }
        }
    }
    
    //# MARK: - Initialize
    fileprivate func initializeCollectionView() {
        
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
        collectionViewFlowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    fileprivate func initializeForceTouch() {
        
        if traitCollection.forceTouchCapability == .available {
            
            registerForPreviewing(with: self, sourceView: view)
        }
        else {
            let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler))
            photoAlbumCollectionView.addGestureRecognizer(longPressGestureRecognizer)
        }
    }
    
    fileprivate func initializeButton() {
        
        if Constants.AddImagesWithoutDeletion {
            reloadButton.setTitle(Constants.AddNewImagesText, for: UIControlState())
        }
        else {
            reloadButton.setTitle(Constants.LoadNewImagesText, for: UIControlState())
        }
    }
    
    //# MARK: Map
    fileprivate func showPinOnMap(_ pin: Pin) {
        
        let location = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
        let mapItem = MapItem(title: pin.title!, location: location)
        mapView.addAnnotation(mapItem)
    }
    
    fileprivate func setCurrentLocation(_ pin: Pin) {
        
        let coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    //# MARK: Images
    fileprivate func createEmptyImageDictionary(_ imageDatas: [ImageData]) -> [String:UIImage] {
        
        var images = [String:UIImage]()
        
        if imageDatas.count > 0 {
            
            for imageData in imageDatas {
                images[imageData.url!] = nil
            }
        }
        
        return images
    }
    
    fileprivate func loadImages(_ pin: Pin) {
        
        noImagesTextField.isHidden = true
        
        DataStore.sharedInstance().getImages(pin) { (success, results, error) in
            
            let resultsCount = results.imageDatas?.count
            
            if success {
                Utils.GlobalMainQueue.async {
                    
                    if resultsCount > 0 {
                        
                        self.imageDatas = results.imageDatas?.allObjects as! [ImageData]
                        self.images = self.createEmptyImageDictionary(self.imageDatas)
                        self.photoAlbumCollectionView.reloadData()
                        
                        self.createUIImages()
                    }
                    else {
                        self.noImagesTextField.isHidden = false
                    }
                }
            }
            else {
                print(error as Any)
                Utils.showAlert(self, alertMessage: "An error occured while loading images from flickr.", completion: nil)
            }
        }
    }
    
    fileprivate func createUIImages() {
        
        reloadButton.isEnabled = false
        isCreatingImages = true
        
        Utils.GlobalBackgroundQueue.async {
            
            let downloadGroup = DispatchGroup()
            
            for imageData in self.imageDatas {
                
                var photo_url: String = ""
                var noImage: Bool = false
                var imgDataImage: Data?
                
                Utils.GlobalMainQueue.sync {
                    photo_url = imageData.url!
                    imgDataImage = imageData.image
                    noImage = imageData.image == nil
                }
                
                downloadGroup.enter()
                
                if noImage {
                    
                    if let url = URL(string: photo_url) {
                        if let data = try? Data(contentsOf: url) {
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
                
                Utils.GlobalMainQueue.async {
                    
                    imageData.image = imgDataImage
                    self.photoAlbumCollectionView.reloadData()
                }
                
                downloadGroup.leave()
            }
            
            _ = downloadGroup.wait(timeout: DispatchTime.distantFuture)
            Utils.GlobalMainQueue.async {
                
                self.reloadButton.isEnabled = true
                self.isCreatingImages = false
            }
            
            DataStore.sharedInstance().saveContext() { (success, error) in
                
                if !success {
                    print(error as Any)
                    Utils.showAlert(self, alertMessage: "An error occured while saving the images to the data base.", completion: nil)
                }
            }
            
            if Constants.ScrollToBottom {
                
                let itemIndex = self.collectionView(self.photoAlbumCollectionView, numberOfItemsInSection: 0) - 1
                let lastItemIndex = IndexPath(item: itemIndex, section: 0)
                self.photoAlbumCollectionView.scrollToItem(at: lastItemIndex, at: .bottom, animated: true)
            }
        }
    }
    
    fileprivate func deleteImage(_ index: Int) {
        
        let imageData = imageDatas[index]
        images.removeValue(forKey: imageData.url!)
        imageDatas.remove(at: index)
        
        if (images.count == 0) {
            noImagesTextField.isHidden = false
        }
        
        DataStore.sharedInstance().deleteImageData(imageData) { (success, error) in
            
            if !success {
                print(error as Any)
                Utils.showAlert(self, alertMessage: "An error occured while deleting the image.", completion: nil)
            }
        }
    }
    
    
    //# MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if isCreatingImages {
            Utils.showAlert(self, alertMessage: "Cannot delete images while loading. Please wait until all images are loaded.", completion: nil)
            return
        }
        
        deleteImage(indexPath.row)
        collectionView.deleteItems(at: [indexPath])
    }
    
    
    //# MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return imageDatas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! CustomCollectionViewCell
        
        let imageData = imageDatas[indexPath.row]
        if imageData.image == nil {
            cell.activityIndicator.isHidden = false
        }
        else {
            cell.imageView.image = images[imageData.url!]
            cell.activityIndicator.isHidden = true
        }
        
        return cell
    }
    
    
    //# MARK: - UIViewControllerPreviewingDelegate
    //          Can only be used with devices that support force touch
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let offset = photoAlbumCollectionView.frame.origin.y
        let contentOffset = photoAlbumCollectionView.contentOffset.y
        
        let tapLocation = CGPoint(x: location.x, y: location.y - offset + contentOffset)
        
        guard let indexPath = photoAlbumCollectionView?.indexPathForItem(at: tapLocation) else { return nil }
        guard let cell = photoAlbumCollectionView?.cellForItem(at: indexPath) else { return nil }
        guard let photoDetailViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoDetailViewController") as? PhotoDetailViewController else { return nil }
        
        let imageData = imageDatas[indexPath.row]
        let image = images[imageData.url!]
        photoDetailViewController.image = image
        
        photoDetailViewController.preferredContentSize = CGSize(width: 0.0, height: 500)
        previewingContext.sourceRect = cell.frame
        
        return photoDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
    }
    
    func longPressHandler(_ recognizer: UILongPressGestureRecognizer)
    {
        guard recognizer.state == UIGestureRecognizerState.began else { return }
        
        let offset = photoAlbumCollectionView.frame.origin.y
        let contentOffset = photoAlbumCollectionView.contentOffset.y
        
        let location = recognizer.location(in: self.view)
        let tapLocation = CGPoint(x: location.x, y: location.y - offset + contentOffset)
        
        guard let indexPath = photoAlbumCollectionView?.indexPathForItem(at: tapLocation) else { return }
        guard let photoDetailViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoDetailViewController") as? PhotoDetailViewController else { return }
        
        let imageData = imageDatas[(indexPath.row)]
        let image = images[imageData.url!]
        photoDetailViewController.image = image
        
        show(photoDetailViewController, sender: self)
    }
}
