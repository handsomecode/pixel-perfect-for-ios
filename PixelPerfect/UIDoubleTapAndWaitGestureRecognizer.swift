import UIKit
import UIKit.UIGestureRecognizerSubclass

class UIDoubleTapAndWaitGestureRecognizer : UIGestureRecognizer {
    
    private let kJustTapInterval = 0.1
    private let kDoubleTapInterval = 0.2
    private let kWailInterval = 0.6
    private let touchSlop : CGFloat = 2
    
    private var doubleTapTimer : NSTimer?
    private var waitTimer : NSTimer?
    private var justTapTimer : NSTimer?
    private var isFirstTapDetected = false
    private var isDoubleTapDetected = false
    private var startTouchPoint : CGPoint?
    
    var isSecondJustTap = false
    
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
            isSecondJustTap = false
            isFirstTapDetected = true
            
            doubleTapTimer = NSTimer.scheduledTimerWithTimeInterval(kDoubleTapInterval, target: self, selector: "doubleTapTimeExpired", userInfo: nil, repeats: false)
        } else {
            isFirstTapDetected = false
            isDoubleTapDetected = true
            isSecondJustTap = true
            doubleTapTimer?.invalidate()
            waitTimer = NSTimer.scheduledTimerWithTimeInterval(kWailInterval, target: self, selector: "waitTimeExpired", userInfo: nil, repeats: false)
            justTapTimer = NSTimer.scheduledTimerWithTimeInterval(kJustTapInterval, target: self, selector: "justTapExpired", userInfo: nil, repeats: false)
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
    
    func justTapExpired() {
        isSecondJustTap = false
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        if isDoubleTapDetected {
            state = isSecondJustTap ? .Ended : .Failed
            waitTimer?.invalidate()
            justTapTimer?.invalidate()
        }
        isDoubleTapDetected = false
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        if let currentTouch = touches.first, let startTouchPoint = startTouchPoint, let view = view {
            let currentTouchPoint = currentTouch.locationInView(view)
            if abs(currentTouchPoint.x - startTouchPoint.x) > touchSlop ||
                abs(currentTouchPoint.y - startTouchPoint.y) > touchSlop {
                    state = .Failed
                    waitTimer?.invalidate()
                    doubleTapTimer?.invalidate()
                    isFirstTapDetected = false
                    isDoubleTapDetected = false
            }
        }
    }
}