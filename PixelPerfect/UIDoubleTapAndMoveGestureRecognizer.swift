import UIKit
import UIKit.UIGestureRecognizerSubclass

class UIDoubleTapAndMoveGestureRecognizer : UIGestureRecognizer {
    
    private let kDoubleTapInterval = 0.2
    private let kWailInterval = 0.6
    private let touchSlop : CGFloat = 2
    
    private var doubleTapTimer : NSTimer?
    private var isFirstTapDetected = false
    private var isDoubleTapDetected = false
    private var startTouchPoint : CGPoint?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        if touches.count != 1 || isDoubleTapDetected {
            isFirstTapDetected = false
            state = .Failed
            return
        }
        if let touch = touches.first, let view = view {
            startTouchPoint = touch.locationInView(view)
        }
        if !isFirstTapDetected {
            isFirstTapDetected = true
            isDoubleTapDetected = false
            
            doubleTapTimer = NSTimer.scheduledTimerWithTimeInterval(kDoubleTapInterval, target: self, selector: "doubleTapTimeExpired", userInfo: nil, repeats: false)
            state = .Possible
        } else {
            isDoubleTapDetected = true
            isFirstTapDetected = false
            doubleTapTimer?.invalidate()
            state = .Possible
        }
    }
    
    func doubleTapTimeExpired() {
        state = .Failed
        isFirstTapDetected = false
        isDoubleTapDetected = false
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        if isDoubleTapDetected {
            state = .Ended
        }
        isDoubleTapDetected = false
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        if state != .Changed {
            if let currentTouch = touches.first, let startTouchPoint = startTouchPoint, let view = view {
                let currentTouchPoint = currentTouch.locationInView(view)
                if abs(currentTouchPoint.x - startTouchPoint.x) > touchSlop ||
                    abs(currentTouchPoint.y - startTouchPoint.y) > touchSlop {
                        isFirstTapDetected = false
                        doubleTapTimer?.invalidate()
                        if !isDoubleTapDetected {
                            state = .Failed
                            return
                        }
                        state = .Changed
                }
            }
            return
        }
        state = .Changed
    }
}