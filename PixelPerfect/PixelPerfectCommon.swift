//
//  PixelPerfectCommon.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 05/01/16.
//  Copyright © 2016 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectCommon {
    
    private static let kBundleName = "pixelperfect"
    private static let kBundleExt = "bundle"
    
    class func bundle() -> NSBundle {
        return NSBundle(identifier: "is.handsome.PixelPerfect")!
    }
    
    class func imageByName(name : String) -> UIImage? {
        return UIImage(named: "\(kBundleName).\(kBundleExt)/\(name)")!
    }
    
    class func getImagesBundlePath() -> String? {
        if let path = NSBundle.mainBundle().pathForResource(kBundleName, ofType: kBundleExt), let bundle = NSBundle(path: path) {
            return bundle.resourcePath
        }
        return nil
    }
}