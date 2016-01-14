//
//  UIShortPressGestureRecognizer.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 12/01/16.
//  Copyright © 2016 Handsome. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class UIShortPressGestureRecognizer : UIGestureRecognizer {
    
    private var timer : NSTimer?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        if touches.count != 1 {
            state = .Failed
            return
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "shortPressTimeExpired", userInfo: nil, repeats: false)
        state = .Possible
    }
    
    func shortPressTimeExpired() {
        state = .Began
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        timer?.invalidate()
        state = state == .Possible ? .Failed : .Ended
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        state = .Changed
    }
}