//
//  UIDoubleTapAndWaitGestureRecognizer.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 23/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class UIDoubleTapAndWaitGestureRecognizer : UIGestureRecognizer {
    
    private let kDoubleTapInterval = 0.2
    private let kWailInterval = 0.6
    
    private var doubleTapTimer : NSTimer?
    private var waitTimer : NSTimer?
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
            
            doubleTapTimer = NSTimer.scheduledTimerWithTimeInterval(kDoubleTapInterval, target: self, selector: "doubleTapTimeExpired", userInfo: nil, repeats: false)
            state = .Possible
        } else {
            isFirstTapDetected = false
            isDoubleTapDetected = true
            doubleTapTimer?.invalidate()
            waitTimer = NSTimer.scheduledTimerWithTimeInterval(kWailInterval, target: self, selector: "waitTimeExpired", userInfo: nil, repeats: false)
            state = .Began
        }
    }
    
    func doubleTapTimeExpired() {
        state = .Failed
        isFirstTapDetected = false
        isDoubleTapDetected = false
    }
    
    func waitTimeExpired() {
        state = .Ended
        isFirstTapDetected = false
        isDoubleTapDetected = false
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        if isDoubleTapDetected {
            state = .Failed
            waitTimer?.invalidate()
        }
        isDoubleTapDetected = false
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        state = .Failed
        waitTimer?.invalidate()
        doubleTapTimer?.invalidate()
        isFirstTapDetected = false
        isDoubleTapDetected = false
    }
}