//
//  CustomCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Sascha Stanic on 09.06.16.
//  Copyright © 2016 Sascha Stanic. All rights reserved.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    
    //# MARK: Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    //# MARK: Overrides
    override func prepareForReuse() {
        
        imageView.image = nil
        
        super.prepareForReuse()
    }
}
