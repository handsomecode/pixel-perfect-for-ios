//
//  PixelPerfectImageViewCell.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 24/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectItemViewCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    func setup(image : UIImage?, label : String) {
        self.image.image = image
        self.label.text = label
    }
    
}