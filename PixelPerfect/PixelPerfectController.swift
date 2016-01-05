//
//  PixelPerfectController.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 15/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

public class PixelPerfectController {
    
    private static let sharedInstance = PixelPerfectController()
    
    private static var shown = false
    private static var pixelPerfectLayout : PixelPerfectLayout!
    
    public static func isShown() -> Bool {
        if let window = UIApplication.sharedApplication().delegate!.window, let views = window?.subviews, let pixelPerfectLayout = pixelPerfectLayout {
            return views.contains(pixelPerfectLayout)
        }
        return false
    }
    
    public static func show(name : String? = nil) {
        if let window = UIApplication.sharedApplication().delegate!.window {
            if pixelPerfectLayout == nil {
                pixelPerfectLayout = PixelPerfectLayout(frame: window!.frame)
            }
            if let name = name {
                pixelPerfectLayout.setImage(name)
            }
            window!.addSubview(pixelPerfectLayout)
        }
    }
    
    public static func hide() {
        if let pixelPerfectView = pixelPerfectLayout {
            pixelPerfectView.removeFromSuperview()
        }
    }
}