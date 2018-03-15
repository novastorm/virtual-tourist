//
//  PinPhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/20/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import UIKit

class PinPhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func showImage(_ imageData: Data) {
        activityIndicator.stopAnimating()
        imageView.image = UIImage(data: imageData)
    }
    
    func showLoading() {
        imageView.image = nil
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }
}
