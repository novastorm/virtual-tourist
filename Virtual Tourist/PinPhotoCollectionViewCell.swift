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
    
    func configure(withPhoto photo: Photo) {
        guard let imageData = photo.imageData else {
            showLoading()
            return
        }

        showImage(imageData)

    }
    
    func showImage(imageData: NSData) {
        activityIndicator.stopAnimating()
        imageView.image = UIImage(data: imageData)
    }
    
    func showLoading() {
        imageView.image = nil
        activityIndicator.startAnimating()
        activityIndicator.hidden = false
    }
}