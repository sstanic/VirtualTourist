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
    
    var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeCollectionView()
        initializeTestImages()
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
        collectionViewFlowLayout.minimumLineSpacing = space / 4
        collectionViewFlowLayout.itemSize = CGSizeMake(dimension, dimension)
    }
    
    private func initializeTestImages() {
        for _ in 0...20 {
            let img = UIImage(named: "testImage")
            images.append(img!)
        }
    }
    
    @IBAction func reloadImages(sender: AnyObject) {
    }
    
    
    //#MARK: - UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        images.removeAtIndex(indexPath.row)
        collectionView.deleteItemsAtIndexPaths([indexPath])
    }
    
    
    //#MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell

        let img = images[indexPath.row]
        cell.imageView.image = img
        
        return cell
    }
}
