//
//  CollectionViewPhotoCell.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/19/15.
//  Copyright © 2015 notluS. All rights reserved.
//

import UIKit

class CollectionViewPhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var overlayView: UIView! {
        didSet {
            overlayView.hidden = true
        }
    }
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
}
