//
//  PhotoDetailViewController.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 24.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import Foundation
import UIKit

class PhotoDetailViewController: UIViewController {

    //# MARK: Outlets
    @IBOutlet weak var imageView: UIImageView!
    
    
    //# MARK: Attributes
    var image: UIImage?
    
    
    //# MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = image {
            imageView.image = image
        }
        
        initializeGestureRecognizer()
    }
    
    
    //# MARK: - Gesture Recognizer
    fileprivate func initializeGestureRecognizer() {
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchImage))
        imageView.addGestureRecognizer(pinchGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panImage))
        imageView.addGestureRecognizer(panGestureRecognizer)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapImage))
        tapGestureRecognizer.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func pinchImage(_ gestureRecognizer: UIPinchGestureRecognizer) {
        
        let scale: CGFloat = gestureRecognizer.scale;
        gestureRecognizer.view!.transform = gestureRecognizer.view!.transform.scaledBy(x: scale, y: scale);
        gestureRecognizer.scale = 1.0;
    }
    
    @objc func panImage(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        let translate = gestureRecognizer.translation(in: self.view)
        gestureRecognizer.view!.center = CGPoint(x:gestureRecognizer.view!.center.x + translate.x, y:gestureRecognizer.view!.center.y + translate.y)
        gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @objc func tapImage(_ gestureRecognizer: UITapGestureRecognizer) {
        
        imageView.frame = self.view.frame
    }
}
