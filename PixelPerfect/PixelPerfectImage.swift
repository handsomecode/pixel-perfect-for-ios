//
//  PixelPerfectImage.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 18/01/16.
//  Copyright © 2016 Handsome. All rights reserved.
//

import Foundation

public struct PixelPerfectImage {
    public let image : UIImage
    public let imageName : String
    
    public init(image : UIImage, imageName : String) {
        self.image = image
        self.imageName = imageName
    }
}
