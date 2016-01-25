import UIKit
import UIKit.UIGestureRecognizerSubclass

class UIShortPressGestureRecognizer : UIGestureRecognizer {
    
    private let touchSlop : CGFloat = 2
    
    private var timer : NSTimer?
    private var startTouchPoint : CGPoint?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        if touches.count != 1 {
            state = .Failed
            return
        }
        if let touch = touches.first, let view = view {
            startTouchPoint = touch.locationInView(view)
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
        if state == .Possible {
            if let currentTouch = touches.first, let startTouchPoint = startTouchPoint, let view = view {
                let currentTouchPoint = currentTouch.locationInView(view)
                if abs(currentTouchPoint.x - startTouchPoint.x) > touchSlop ||
                    abs(currentTouchPoint.y - startTouchPoint.y) > touchSlop {
                     state = .Changed
                }
            }
            return
        }
        state = .Changed
    }
}