//
//  PixelPerfectConfig.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 16/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import Foundation

struct PixelPerfectConfig {
    
    var imageName : String
    var opacity : CGFloat
    var inverse : Bool
    
    var offsetX : Int
    var offsetY : Int
}

struct PixelPerfectBuilderConfig  {
    
    var image: String?
    var inverse: Bool?
    var transparency: Float?
    var withImages: [PixelPerfectImage]?
    var withBundle: String?
    var imageDensity: CGFloat!
}