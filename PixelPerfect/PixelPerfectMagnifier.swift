//
//  PixelPerfectMagnifier.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 05/01/16.
//  Copyright © 2016 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectMagnifier : UIView, UIGestureRecognizerDelegate {
    
    private let kGridLinesCount : Int = 8
    private let kAreaSize : CGFloat = 200
    private let kZoom : CGFloat = 3
    
    private var showGrid : Bool?
    private var isCircular : Bool?
    
    private var area : CGRect?
    private var appImageFrame : CGRect?
    private var overlayImageFrame : CGRect?
    
    private var appImage : UIImage?
    private var overlayImage : UIImage?
    private var startMovingPoint : CGPoint?
    
    private var dx : CGFloat = 0
    private var dy : CGFloat = 0
    private var overlayAlpha : CGFloat = 0
    
    init (showGrid : Bool, isCircular : Bool) {
        super.init(frame:CGRect.zero)
        self.showGrid = showGrid
        self.isCircular = isCircular
        backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        opaque = false;
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return area!.contains(point)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return area!.contains(touch.locationInView(self))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Magnifier does not support NSCoding")
    }
    
    func setImages(appImage : UIImage?, overlayImage : UIImage?) {
        self.overlayImage = overlayImage
        self.appImage = appImage
        if let appImage = appImage {
            self.frame = CGRect(x: 0, y: 0, width: appImage.size.width, height: appImage.size.height)
        }
        setNeedsDisplay()
    }
    
    func setOverlayOpacity(overlayAlpha : CGFloat) {
        self.overlayAlpha = overlayAlpha
        setNeedsDisplay()
    }
    
    func setOverlayOffset(dx : CGFloat, dy : CGFloat) {
        self.dx = dx
        self.dy = dy
        self.overlayImageFrame = appImageFrame?.offsetBy(dx: dx * kZoom , dy: dy * kZoom)
        setNeedsDisplay()
    }
    
    func setPoint(point : CGPoint) {
        appImageFrame = CGRect(x: -point.x * (kZoom - 1), y: -point.y * (kZoom - 1), width: frame.width * kZoom, height: frame.height * kZoom)
        overlayImageFrame = appImageFrame?.offsetBy(dx: dx * kZoom , dy: dy * kZoom)
        var x = point.x - kAreaSize / 2
        x = x > 0 ? x : 0
        x = x > frame.width - kAreaSize ? frame.width - kAreaSize : x
        var y = point.y - kAreaSize / 2
        y = y > 0 ? y : 0
        y = y > frame.height - kAreaSize ? frame.height - kAreaSize : y
        area = CGRect(x: x, y: y, width: kAreaSize, height: kAreaSize)
        setNeedsDisplay()
    }
    
    func move(point : CGPoint, initialTouchPoint : CGPoint) {
        if startMovingPoint == nil {
            startMovingPoint = CGPoint(x: point.x - initialTouchPoint.x, y: point.y - initialTouchPoint.y)
        }
        
        if let area = area, imageFrame = appImageFrame {
            var areadx = point.x - startMovingPoint!.x
            var aready = point.y - startMovingPoint!.y
            var imagedx = -areadx * (kZoom - 1)
            var imagedy = -aready * (kZoom - 1)
            
            if (area.origin.x == 0) || (area.origin.x + area.width == frame.width) {
                imagedx *= 2
            }
            
            if (area.origin.y == 0) || (area.origin.y + area.height == frame.height) {
                imagedy *= 2
            }
            
            imagedx = imageFrame.origin.x + imagedx > 0 ? -imageFrame.origin.x : imagedx
            imagedx = imageFrame.origin.x + imagedx + imageFrame.width < frame.width ? frame.width - (imageFrame.origin.x + imageFrame.width) : imagedx
            
            imagedy = imageFrame.origin.y + imagedy > 0 ? -imageFrame.origin.y : imagedy
            imagedy = imageFrame.origin.y + imagedy + imageFrame.height <  frame.height ? frame.height - (imageFrame.origin.y + imageFrame.height) : imagedy
            
            areadx = area.origin.x + areadx < 0 ? -area.origin.x : areadx
            areadx = area.origin.x + areadx + area.width > frame.width ? frame.width - (area.origin.x + area.width) : areadx
            
            areadx = imageFrame.origin.x + imagedx > -area.width && area.origin.x == 0 ? 0: areadx
            areadx = imageFrame.origin.x + imageFrame.width + imagedx < frame.width + area.width && area.origin.x == frame.width - area.width ? 0: areadx
            
            aready = area.origin.y + aready < 0 ? -area.origin.y : aready
            aready = area.origin.y + aready + area.height > frame.height ? frame.height - (area.origin.y + area.height) : aready
            
            aready = imageFrame.origin.y + imagedy > -area.height && area.origin.y == 0 ? 0: aready
            aready = imageFrame.origin.y + imageFrame.height + imagedy < frame.height + area.height && area.origin.y == frame.height - area.height ? 0: aready
            
            self.area?.offsetInPlace(dx: areadx, dy: aready)
            self.appImageFrame?.offsetInPlace(dx: imagedx, dy: imagedy)
            self.overlayImageFrame?.offsetInPlace(dx: imagedx, dy: imagedy)
            
            startMovingPoint = point
            setNeedsDisplay()
        }
    }
    
    func endMove() {
        startMovingPoint = nil
    }
    
    func isPointInside(point : CGPoint) -> Bool {
        return area != nil && area!.contains(CGPoint(x: point.x - frame.origin.x, y: point.y - frame.origin.y))
    }
    
    override func drawRect(rect: CGRect) {
        if let area = area, let appImageFrame = appImageFrame, let overlayImageFrame = overlayImageFrame {
            
            let circularPath = isCircular == nil || isCircular! ? UIBezierPath(ovalInRect: area) : UIBezierPath(rect: area)
            circularPath.addClip()
            appImage?.drawInRect(appImageFrame)
            overlayImage?.drawInRect(overlayImageFrame, blendMode: .Normal, alpha: overlayAlpha)
            circularPath.stroke()
            
            guard let showGrid = showGrid else {
                return
            }
            
            if showGrid {
                UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.3).setStroke()
                let linePath = UIBezierPath()
                let linesDelta = kAreaSize / (CGFloat(kGridLinesCount) + 1)
                for i in 0..<kGridLinesCount {
                    linePath.moveToPoint(CGPointMake(area.origin.x + linesDelta * (CGFloat(i) + 1), area.origin.y))
                    linePath.addLineToPoint(CGPointMake(area.origin.x + linesDelta * (CGFloat(i) + 1), area.origin.y + area.size.height))
                    
                    linePath.moveToPoint(CGPointMake(area.origin.x, area.origin.y + linesDelta * (CGFloat(i) + 1)))
                    linePath.addLineToPoint(CGPointMake(area.origin.x + area.size.width, area.origin.y + linesDelta * (CGFloat(i) + 1)))
                }
                linePath.stroke()
            }
        }
    }
}