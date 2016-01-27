import UIKit
import UIKit.UIGestureRecognizerSubclass

class UITripleTapGestureRecognizer : UIGestureRecognizer {
    
    private let touchSlop : CGFloat = 2
    private let kJustTapTapInterval = 0.1
    private let kDoubleTapInterval = 0.2
    private let kTripleTapInterval = 0.75
    
    private var isFirstTapDetected = false
    private var isDoubleTapDetected = false
    private var isTripleTapDetected = false
    private var isJustTap = false
    
    private var timer : NSTimer?
    private var justTapTimer : NSTimer?
    
    private var startTouchPoint : CGPoint?
    
    var isThirdJustTap = false
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        if touches.count != 1 {
            fail()
            return
        }
        if let touch = touches.first, let view = view {
            startTouchPoint = touch.locationInView(view)
        }
        if !isFirstTapDetected {
            isFirstTapDetected = true
            isJustTap = true
            
            timer = NSTimer.scheduledTimerWithTimeInterval(kDoubleTapInterval, target: self, selector: "tapTimeExpired", userInfo: nil, repeats: false)
            justTapTimer = NSTimer.scheduledTimerWithTimeInterval(kJustTapTapInterval, target: self, selector: "justTapTimeExpired", userInfo: nil, repeats: false)
            state = .Possible
        } else if !isDoubleTapDetected {
            isDoubleTapDetected = true
            isJustTap = true
            
            timer?.invalidate()
            timer = NSTimer.scheduledTimerWithTimeInterval(kTripleTapInterval, target: self, selector: "tapTimeExpired", userInfo: nil, repeats: false)
            justTapTimer = NSTimer.scheduledTimerWithTimeInterval(kJustTapTapInterval, target: self, selector: "justTapTimeExpired", userInfo: nil, repeats: false)
        } else {
            isTripleTapDetected = true
            isJustTap = true
            isThirdJustTap = true
            timer?.invalidate()
            justTapTimer = NSTimer.scheduledTimerWithTimeInterval(kJustTapTapInterval, target: self, selector: "justTapTimeExpired", userInfo: nil, repeats: false)
            state = .Began
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        justTapTimer?.invalidate()
        if !isJustTap && !isTripleTapDetected {
            fail()
            return
        }
        if state == .Began || state == .Changed {
            clear()
            state = .Ended
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        justTapTimer?.invalidate()
        if state == .Possible {
            if let currentTouch = touches.first, let startTouchPoint = startTouchPoint, let view = view {
                let currentTouchPoint = currentTouch.locationInView(view)
                if abs(currentTouchPoint.x - startTouchPoint.x) > touchSlop ||
                    abs(currentTouchPoint.y - startTouchPoint.y) > touchSlop {
                        state = .Changed
                }
            }
        }
        if !isTripleTapDetected {
            fail()
            return
        }
        state = .Changed
    }
    
    func tapTimeExpired() {
        fail()
    }
    
    func justTapTimeExpired() {
        isJustTap = false
        if isTripleTapDetected {
            state = .Changed
            isThirdJustTap = false
        }
    }
    
    private func clear() {
        isFirstTapDetected = false
        isDoubleTapDetected = false
        isTripleTapDetected = false
    }
    
    private func fail() {
        clear()
        state = .Failed
        timer?.invalidate()
    }

}