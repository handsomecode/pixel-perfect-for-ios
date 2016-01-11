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
    
    private let imageView = UIImageView()
    private let opacitySlider = PixelPerfectSlider()
    private var popover : PixelPerfectPopover!
    private var magnifier : PixelPerfectMagnifier?
    private var microPositioningEnabled : Bool!
    private var config : PixelPerfectConfig?
    
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
        addSlider()
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
        popover.restore(getConfigOrDefault())
        popover.didClose = { pixelPerfectConfig in
            self.config = pixelPerfectConfig
            self.abortTouch = pixelPerfectConfig.active
            self.setImage(pixelPerfectConfig.imageName)
            self.popover.removeFromSuperview()
            self.popover = nil
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
            magnifier = PixelPerfectMagnifier(showGrid: getConfigOrDefault().grid, isCircular: getConfigOrDefault().magnifierCircular)
            
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
            //actionButton.fixOffset(-Int(imageView.frame.origin.x * UIScreen.mainScreen().scale), y: -Int(imageView.frame.origin.y * UIScreen.mainScreen().scale))
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
            startDraggingPoint = gestureRecognizer.locationInView(self)
            microPositioningEnabled = true
        } else if gestureRecognizer.state == .Ended || gestureRecognizer.state == .Failed {
            isHorizontalDragging = nil
            microPositioningEnabled = true
        } else {
            guard let startDraggingPoint = startDraggingPoint else {
                return
            }
            let currentDraggingPoint = gestureRecognizer.locationInView(self)
            if isHorizontalDragging == nil {
                isHorizontalDragging = abs(currentDraggingPoint.x - startDraggingPoint.x) > abs(currentDraggingPoint.y - startDraggingPoint.y)
            }
            if microPositioningEnabled! {
                microPositioningEnabled = abs(currentDraggingPoint.x - startDraggingPoint.x) < kMicroPositioningOffset && abs(currentDraggingPoint.y - startDraggingPoint.y) < kMicroPositioningOffset
            }
            if isHorizontalDragging! {
                imageView.center.x += microPositioningEnabled! ? (currentDraggingPoint.x - startDraggingPoint.x) / kMicroPositioningFactor : currentDraggingPoint.x - startDraggingPoint.x
            } else {
                imageView.center.y += microPositioningEnabled! ? (currentDraggingPoint.y - startDraggingPoint.y) / kMicroPositioningFactor : currentDraggingPoint.y - startDraggingPoint.y
            }
            self.startDraggingPoint = currentDraggingPoint
            
            //actionButton.setOffset(-Int(imageView.frame.origin.x * UIScreen.mainScreen().scale), y: -Int(imageView.frame.origin.y * UIScreen.mainScreen().scale))
            
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
    
    private func addSlider() {
        opacitySlider.translatesAutoresizingMaskIntoConstraints = false
        opacitySlider.didValueChanged = { value in
            self.imageView.alpha = value
            if let magnifier = self.magnifier {
                magnifier.setOverlayOpacity(value)
            }
        }
        addSubview(opacitySlider)

        addEqualConstraint(opacitySlider, constant: 0, attribute: .Trailing, parent: self)
        addEqualConstraint(opacitySlider, constant: 20, attribute: .Width, parent: nil)
        addEqualConstraint(opacitySlider, constant: 20, attribute: .Top, parent: self)
        addEqualConstraint(opacitySlider, constant: -20, attribute: .Bottom, parent: self)
    }
    
    private func addGestureRecognizers() {
        let move =  UIPanGestureRecognizer(target: self, action: "moveImage:")
        move.delegate = self
        imageView.addGestureRecognizer(move)
        
        let doubleTapAndWait =  UIDoubleTapAndWaitGestureRecognizer(target: self, action: "resetPosition:")
        imageView.addGestureRecognizer(doubleTapAndWait)
        
        let doubleTapAndMove =  UIDoubleTapAndMoveGestureRecognizer(target: self, action: "changeOpacity:")
        doubleTapAndMove.requireGestureRecognizerToFail(doubleTapAndWait)
        imageView.addGestureRecognizer(doubleTapAndMove)
        
        let tap =  UITapGestureRecognizer(target: self, action: "actionPressed:")
        tap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tap)
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
    
    private func getConfigOrDefault() -> PixelPerfectConfig {
        if config != nil {
            return config!
        }
        config = PixelPerfectConfig(active : true, imageName : imagesNames.count == 0 ? "" : imagesNames[0], grid : false, magnifierCircular : false)
        return config!
    }
    
    private func hideMagnifierIfNeeded() -> Bool {
        guard let magnifier = magnifier else {
            return false
        }
        magnifier.removeFromSuperview()
        self.magnifier = nil
        return true
    }
}