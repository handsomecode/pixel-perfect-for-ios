//
//  PixelPerfectLayout.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 15/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectLayout : PixelPerfectView, UIGestureRecognizerDelegate {
    
    private let kMicroPositioningOffset : CGFloat = 7
    private let kMicroPositioningFactor : CGFloat = 7
    
    private var imagesNames : [String]!
    private var currentImage : String = ""
    private var abortTouch = true
    private var startDraggingPoint : CGPoint? = nil
    private var startOpacityPoint : CGPoint? = nil
    private var startOpacityValue : CGFloat!
    private var isHorizontalDragging : Bool? = nil
    private var isMicroPositioningEnabled : Bool!
    private var fixedOverlayOffset = CGPoint(x: 0, y: 0)
    private var inverse = false
    private var config : PixelPerfectConfig?
    
    private let imageView = UIImageView()
    private var popover : PixelPerfectPopover!
    private var magnifier : PixelPerfectMagnifier?
    private var offsetView : PixelPerfectOffsetView?
    
    private var actionButtonTrailing : NSLayoutConstraint!
    private var actionButtonBottom : NSLayoutConstraint!
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        
        if let bundlePath = PixelPerfectCommon.getImagesBundlePath() {
            do {
                imagesNames = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(bundlePath)
                setImage(imagesNames[0])
            } catch {
                imagesNames = []
            }
        } else {
            imagesNames = []
        }
        
        addImageView()
        addGestureRecognizers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("PixelPerfectLayout does not support NSCoding")
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return imageView.frame.contains(point) || popover != nil
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return popover == nil
    }
    
    func actionPressed(gestureRecognizer:UIGestureRecognizer) {
        if popover != nil {
            return
        }
        hideMagnifierIfNeeded()
        popover = PixelPerfectCommon.bundle().loadNibNamed("PixelPerfectPopover", owner: self, options: nil).first as! PixelPerfectPopover
        popover.setImageNames(imagesNames)
        popover.restore(getConfig())
        popover.didClose = { pixelPerfectConfig in
            self.config = pixelPerfectConfig
            self.setImage(pixelPerfectConfig.imageName)
            self.imageView.alpha = pixelPerfectConfig.opacity
            if self.inverse != pixelPerfectConfig.inverse {
                self.inverse = pixelPerfectConfig.inverse
                self.imageView.invertImage()
            }
            self.popover.removeFromSuperview()
            self.popover = nil
        }
        popover.didFixOffset = {
            self.fixedOverlayOffset = CGPoint(x: Int(self.imageView.frame.origin.x * UIScreen.mainScreen().scale), y: Int(self.imageView.frame.origin.y * UIScreen.mainScreen().scale))
        }
        popover.translatesAutoresizingMaskIntoConstraints = false
        addSubview(popover)
        
        addEqualConstraint(popover, constant: 10, attribute: .Leading, parent: self)
        addEqualConstraint(popover, constant: -10, attribute: .Trailing, parent: self)
        addEqualConstraint(popover, constant: 20, attribute: .Top, parent: self)
        addEqualConstraint(popover, constant: -20, attribute: .Bottom, parent: self)
    }
    
    func showZoom(gestureRecognizer:UIGestureRecognizer) {
        if popover != nil {
            return
        }
        if hideMagnifierIfNeeded() {
            return
        }
        if gestureRecognizer.state == .Ended {
            magnifier = PixelPerfectMagnifier()
            
            imageView.hidden = true
            let appImage = makeScreenshot()
            imageView.hidden = false
            magnifier!.setImages(appImage, overlayImage: imageView.image)
            magnifier!.setOverlayOffset(imageView.frame.origin.x, dy: imageView.frame.origin.y)
            magnifier!.setOverlayOpacity(imageView.alpha)
            magnifier!.setPoint(gestureRecognizer.locationInView(self))
            
            let move =  UIPanGestureRecognizer(target: self, action: "moveMagnifier:")
            move.delegate = magnifier
            magnifier!.addGestureRecognizer(move)
            
            let tap =  UITapGestureRecognizer(target: self, action: "tapMagnifier:")
            magnifier!.addGestureRecognizer(tap)
            addSubview(magnifier!)
        }
    }
    
    func tapMagnifier(gestureRecognizer:UIGestureRecognizer) {
        guard let magnifier = magnifier else {
            return
        }
        let finger = gestureRecognizer.locationInView(self)
        if !magnifier.isPointInside(finger) {
            hideMagnifierIfNeeded()
        }
    }
    
    func moveMagnifier(gestureRecognizer:UIPanGestureRecognizer) {
        guard let magnifier = magnifier else {
            return
        }
        let finger = gestureRecognizer.locationInView(self)
        if gestureRecognizer.state == .Ended {
            magnifier.endMove()
        } else {
            magnifier.move(finger, initialTouchPoint: gestureRecognizer.translationInView(self))
        }
    }
    
    func resetPosition(gestureRecognizer:UIPanGestureRecognizer) {
        if gestureRecognizer.state == .Ended {
            fixedOverlayOffset = CGPoint(x: Int(imageView.frame.origin.x * UIScreen.mainScreen().scale), y: Int(imageView.frame.origin.y * UIScreen.mainScreen().scale))
        }
    }
    
    func changeOpacity(gestureRecognizer:UIGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            startOpacityPoint = gestureRecognizer.locationInView(self)
            startOpacityValue = imageView.alpha
        } else if gestureRecognizer.state == .Changed {
            guard let startPoint = startOpacityPoint else {
                return
            }
            let currentPoint = gestureRecognizer.locationInView(self)
            imageView.alpha = startPoint.y - currentPoint.y
            if startPoint.y - currentPoint.y > 0 {
                imageView.alpha = startOpacityValue * (1 - (startPoint.y - currentPoint.y) / startPoint.y) + 0.01
            } else {
                imageView.alpha = startOpacityValue + (currentPoint.y - startPoint.y) / (frame.height - startPoint.y) * (1 - startOpacityValue)
            }
        }
    }
    
    func moveImage(gestureRecognizer:UIGestureRecognizer) {
        if popover != nil {
            return
        }
        if gestureRecognizer.state == .Began {
            offsetView = PixelPerfectCommon.bundle().loadNibNamed("PixelPerfectOffsetView", owner: self, options: nil).first as? PixelPerfectOffsetView
            //offsetView?.frame = CGRect(origin: gestureRecognizer.locationInView(self), size: CGSize(width: 100, height: 50))
            addSubview(offsetView!)
            updateOffsetView(gestureRecognizer.locationInView(self))
            
            startDraggingPoint = gestureRecognizer.locationInView(self)
            isMicroPositioningEnabled = true
        } else if gestureRecognizer.state == .Ended || gestureRecognizer.state == .Failed {
            offsetView?.removeFromSuperview()
            offsetView = nil
            isHorizontalDragging = nil
            isMicroPositioningEnabled = true
        } else if gestureRecognizer.state == .Changed {
            updateOffsetView(gestureRecognizer.locationInView(self))
            
            guard let startDraggingPoint = startDraggingPoint else {
                return
            }
            let currentDraggingPoint = gestureRecognizer.locationInView(self)
            if isHorizontalDragging == nil {
                isHorizontalDragging = abs(currentDraggingPoint.x - startDraggingPoint.x) > abs(currentDraggingPoint.y - startDraggingPoint.y)
            }
            if isMicroPositioningEnabled! {
                isMicroPositioningEnabled = isHorizontalDragging! ? abs(currentDraggingPoint.x - startDraggingPoint.x) < kMicroPositioningOffset : abs(currentDraggingPoint.y - startDraggingPoint.y) < kMicroPositioningOffset
            }
            if isHorizontalDragging! {
                imageView.center.x += isMicroPositioningEnabled! ? (currentDraggingPoint.x - startDraggingPoint.x) / kMicroPositioningFactor : currentDraggingPoint.x - startDraggingPoint.x
            } else {
                imageView.center.y += isMicroPositioningEnabled! ? (currentDraggingPoint.y - startDraggingPoint.y) / kMicroPositioningFactor : currentDraggingPoint.y - startDraggingPoint.y
            }
            self.startDraggingPoint = currentDraggingPoint
            
            if let magnifier = magnifier {
                magnifier.setOverlayOffset(imageView.frame.origin.x, dy: imageView.frame.origin.y)
            }
            
        }
    }
    
    func setImage(name : String) {
        if name == currentImage {
            return
        }
        currentImage = name
        if let delegate = UIApplication.sharedApplication().delegate, let optionalWindow = delegate.window, let window = optionalWindow, let image = PixelPerfectCommon.imageByName(name) {
            let ratio = image.size.height / image.size.width
            let frame = CGRect(x: 0, y: 0, width: window.frame.width, height: window.frame.width * ratio)
            imageView.frame = frame
            imageView.image = image
        }
    }
    
    private func addImageView() {
        addSubview(imageView)
        imageView.alpha = 0.5
        imageView.userInteractionEnabled = true
    }
    
    private func addGestureRecognizers() {
        let doubletap =  UITapGestureRecognizer(target: self, action: "showZoom:")
        doubletap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubletap)
        
        let doubleTapAndWait =  UIDoubleTapAndWaitGestureRecognizer(target: self, action: "resetPosition:")
        doubleTapAndWait.requireGestureRecognizerToFail(doubletap)
        imageView.addGestureRecognizer(doubleTapAndWait)
        
        let tap =  UITapGestureRecognizer(target: self, action: "actionPressed:")
        tap.numberOfTapsRequired = 1
        tap.requireGestureRecognizerToFail(doubleTapAndWait)
        imageView.addGestureRecognizer(tap)
        
        let shortPress = UIShortPressGestureRecognizer(target: self, action: "moveImage:")
        shortPress.requireGestureRecognizerToFail(doubleTapAndWait)
        imageView.addGestureRecognizer(shortPress)
    }
    
    private func makeScreenshot(view : UIView? = nil) -> UIImage? {
        var layer : CALayer?
        if let view = view {
            layer = view.layer
        } else if let delegate = UIApplication.sharedApplication().delegate, let optionalWindow = delegate.window, let window = optionalWindow {
            layer = window.layer
        }
        if layer != nil {
            UIGraphicsBeginImageContextWithOptions(self.frame.size, self.opaque, 0.0)
            layer!.renderInContext(UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
    
    private func getConfig() -> PixelPerfectConfig {
        return PixelPerfectConfig(imageName : currentImage, opacity : imageView.alpha, inverse : inverse, offsetX : -Int(imageView.frame.origin.x * UIScreen.mainScreen().scale - fixedOverlayOffset.x), offsetY: -Int(imageView.frame.origin.y * UIScreen.mainScreen().scale - fixedOverlayOffset.y))
    }
    
    private func hideMagnifierIfNeeded() -> Bool {
        guard let magnifier = magnifier else {
            return false
        }
        magnifier.removeFromSuperview()
        self.magnifier = nil
        return true
    }
    
    private func updateOffsetView(fingerPosition : CGPoint) {
        offsetView?.showOffset(-Int(imageView.frame.origin.x * UIScreen.mainScreen().scale - fixedOverlayOffset.x), y: -Int(imageView.frame.origin.y * UIScreen.mainScreen().scale - fixedOverlayOffset.y))
        offsetView?.center = CGPoint(x: fingerPosition.x, y: fingerPosition.y - 20)
    }
}