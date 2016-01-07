//
//  PixelPerfectSlider.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 05/01/16.
//  Copyright © 2016 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectSlider: UIView {
    
    var didValueChanged : ((CGFloat)->())?
    
    convenience init () {
        self.init(frame:CGRect.zero)
        let move =  UIPanGestureRecognizer(target: self, action: "didFingerMoved:")
        addGestureRecognizer(move)
    }
    
    func didFingerMoved(gestureRecognizer:UIGestureRecognizer) {
        let position = gestureRecognizer.locationInView(self)
        if position.x > 0 && position.x < frame.width {
            didValueChanged?(1 - position.y / frame.height)
        }
    }
}