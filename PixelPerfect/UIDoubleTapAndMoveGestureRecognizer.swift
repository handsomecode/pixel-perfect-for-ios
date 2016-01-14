//
//  UIDoubleTapAndMoveGestureRecognizer.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 12/01/16.
//  Copyright © 2016 Handsome. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class UIDoubleTapAndMoveGestureRecognizer : UIGestureRecognizer {
    
    private var timer : NSTimer?
    private var isFirstTapDetected = false
    private var isDoubleTapDetected = false
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        if touches.count != 1 || isDoubleTapDetected {
            isFirstTapDetected = false
            state = .Failed
            return
        }
        if !isFirstTapDetected {
            isFirstTapDetected = true
            
            timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "doubleTapTimeExpired", userInfo: nil, repeats: false)
            state = .Possible
        } else {
            isFirstTapDetected = false
            isDoubleTapDetected = true
            timer?.invalidate()
            state = .Began
        }
    }
    
    func doubleTapTimeExpired() {
        state = .Failed
        isFirstTapDetected = false
        isDoubleTapDetected = false
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        if !isFirstTapDetected {
            state = .Ended
        }
        isDoubleTapDetected = false
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        if !isDoubleTapDetected {
            state = .Failed
        }
        if state == .Failed {
            isFirstTapDetected = false
            isDoubleTapDetected = false
            return
        }
        state = .Changed
    }
}