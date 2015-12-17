//
//  PixelPerfectController.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 15/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

public class PixelPerfectController {
    
    public static let sharedInstance = PixelPerfectController()
    
    private static var shown = false
    private static var pixelPerfectView : UIView!
    
    public static func isShown() -> Bool {
        if let window = UIApplication.sharedApplication().delegate!.window, let views = window?.subviews, let pixelPerfectView = pixelPerfectView {
            return views.contains(pixelPerfectView)
        }
        return false
    }
    
    public static func show() {
        if let window = UIApplication.sharedApplication().delegate!.window {
            if pixelPerfectView == nil {
                pixelPerfectView = PixelPerfectLayout(frame: window!.frame)
            }
            window!.addSubview(pixelPerfectView)
        }
    }
    
    public static func hide() {
        if let pixelPerfectView = pixelPerfectView {
            pixelPerfectView.removeFromSuperview()
        }
    }
}