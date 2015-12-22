//
//  PixelPerfectLayout.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 15/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectLayout : PixelPerfectView, UIGestureRecognizerDelegate {
    
    private let kBundleName = "pixelperfect"
    private let kBundleExt = "bundle"
    private let kMicroPositioningOffset : CGFloat = 3
    private let kMicroPositioningFactor : CGFloat = 7
    
    private let imageView = UIImageView()
    private let actionButton = CircularButton()
    private let opacitySlider = Slider()
    private var imagesNames : [String]!
    private var currentImage : String = ""
    private var abortTouch = true
    private var startDraggingPoint : CGPoint? = nil
    private var isHorizontalDragging : Bool? = nil
    private var popover : PixelPerfectPopover!
    private var config : PixelPerfectConfig?
    private var magnifier : Magnifier?
    private var microPositioningEnabled : Bool!
    
    private var actionButtonTrailing : NSLayoutConstraint!
    private var actionButtonBottom : NSLayoutConstraint!
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        
        if let path = NSBundle.mainBundle().pathForResource(kBundleName, ofType: kBundleExt), let bundle = NSBundle(path: path), let bundlePath = bundle.resourcePath {
            do {
                imagesNames = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(bundlePath)
                setImage(imagesNames[0])
            } catch {
                imagesNames = []
            }
        } else {
            imagesNames = []
        }
        
        addSubview(imageView)
        imageView.alpha = 0.5
        addActionButton()
        addSlider()
        
        imageView.userInteractionEnabled = true
        
        let tap =  UITapGestureRecognizer(target: self, action: "showZoom:")
        tap.delegate = self
        addGestureRecognizer(tap)
        
        let move =  UIPanGestureRecognizer(target: self, action: "moveImage:")
        move.delegate = self
        move.requireGestureRecognizerToFail(tap)
        imageView.addGestureRecognizer(move)
        
//        let longPress =  UILongPressGestureRecognizer(target: self, action: "moveAfterLongPress:")
//        longPress.delegate = self
//        addGestureRecognizer(longPress)
        
//        let tap =  UITapGestureRecognizer(target: self, action: "moveAfterTap:")
//        tap.requireGestureRecognizerToFail(longPress)
//        imageView.addGestureRecognizer(tap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("PixelPerfectLayout does not support NSCoding")
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return actionButton.frame.contains(point) || popover != nil ? true : abortTouch
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return popover == nil && !actionButton.frame.contains(touch.locationInView(self))
    }
    
    func actionPressed(gestureRecognizer:UIGestureRecognizer) {
        if popover != nil {
            return
        }
        popover = NSBundle.mainBundle().loadNibNamed("PixelPerfectPopover", owner: self, options: nil).first as! PixelPerfectPopover
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
    
    func actionDoubleTapped(gestureRecognizer:UIGestureRecognizer) {
        abortTouch = !abortTouch
        actionButton.selected = abortTouch
        config = PixelPerfectConfig(active : abortTouch, imageName : getConfigOrDefault().imageName, grid : getConfigOrDefault().grid, magnifierCircular : getConfigOrDefault().magnifierCircular)
    }
    
    func actionLongPress(gestureRecognizer:UIGestureRecognizer) {
        if popover != nil {
            return
        }
        if magnifier != nil {
            magnifier!.removeFromSuperview()
            magnifier = nil
        }
        actionButton.center = gestureRecognizer.locationInView(self)
        actionButtonTrailing.constant = actionButton.frame.origin.x + actionButton.frame.width - frame.width
        actionButtonBottom.constant = actionButton.frame.origin.y + actionButton.frame.height - frame.height
        layoutIfNeeded()
    }
    
    func showZoom(gestureRecognizer:UIGestureRecognizer) {
        if popover != nil {
            return
        }
        if magnifier != nil {
            magnifier!.removeFromSuperview()
            self.magnifier = nil
            return
        }
        if gestureRecognizer.state == .Ended {
            magnifier = Magnifier(showGrid: getConfigOrDefault().grid, isCircular: getConfigOrDefault().magnifierCircular)
            actionButton.hidden = true
            magnifier!.setImage(makeScreenshot())
            actionButton.hidden = false
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
            magnifier.removeFromSuperview()
            self.magnifier = nil
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
            
            if let magnifier = magnifier {
                magnifier.hidden = true
                actionButton.hidden = true
                magnifier.setImage(makeScreenshot())
                magnifier.hidden = false
                actionButton.hidden = false
            }
        }
    }
    
    func moveAfterLongPress(gestureRecognizer:UIGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            startDraggingPoint = gestureRecognizer.locationInView(self)
        } else if gestureRecognizer.state == .Ended || gestureRecognizer.state == .Failed {
            isHorizontalDragging = nil
        } else {
            guard let startDraggingPoint = startDraggingPoint else {
                return
            }
            
            let currentDraggingPoint = gestureRecognizer.locationInView(self)
            if isHorizontalDragging == nil {
                isHorizontalDragging = abs(currentDraggingPoint.x - startDraggingPoint.x) > abs(currentDraggingPoint.y - startDraggingPoint.y)
            }
            if isHorizontalDragging! {
                imageView.center.x += (currentDraggingPoint.x - startDraggingPoint.x) / 7
            } else {
                imageView.center.y += (currentDraggingPoint.y - startDraggingPoint.y) / 7
            }
            self.startDraggingPoint = currentDraggingPoint
        }
    }
    
    func moveAfterTap(gestureRecognizer:UIGestureRecognizer) {
        if magnifier != nil {
            magnifier!.removeFromSuperview()
            magnifier = nil
            return
        }
        let tapPoint = gestureRecognizer.locationInView(self)
        if tapPoint.y < frame.height / 3 {
            imageView.center.y -= 1
        } else if tapPoint.y > frame.height * 2 / 3 {
            imageView.center.y += 1
        } else if tapPoint.x < frame.width / 3 {
            imageView.center.x -= 1
        } else if tapPoint.x > frame.width * 2 / 3 {
            imageView.center.x += 1
        }
    }
    
    private func setImage(name : String) {
        if name == currentImage {
            return
        }
        currentImage = name
        if let delegate = UIApplication.sharedApplication().delegate, let optionalWindow = delegate.window, let window = optionalWindow {
            let image = UIImage(named: "\(kBundleName).\(kBundleExt)/\(name)")!
            let ratio = image.size.height / image.size.width
            let frame = CGRect(x: 0, y: 0, width: window.frame.width, height: window.frame.width * ratio)
            imageView.frame = frame
            imageView.image = image
        }
    }
    
    private func addActionButton() {
        actionButton.backgroundColor = UIColor.blackColor()
        actionButton.setImage(UIImage(named: "handsome-logo-inactive"), forState: .Normal)
        actionButton.setImage(UIImage(named: "handsome-logo-active"), forState: .Selected)
        actionButton.imageEdgeInsets = UIEdgeInsets.init(top: 20, left: 20, bottom: 20, right: 20)
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionButton)
        
        actionButtonTrailing = addEqualConstraint(actionButton, constant: -10, attribute: .Trailing, parent: self)
        actionButtonBottom = addEqualConstraint(actionButton, constant: -10, attribute: .Bottom, parent: self)
        addEqualConstraint(actionButton, constant: 60, attribute: .Width, parent: nil)
        addEqualConstraint(actionButton, constant: 60, attribute: .Height, parent: nil)
        
        let longPress =  UILongPressGestureRecognizer(target: self, action: "actionLongPress:")
        actionButton.addGestureRecognizer(longPress)
        
        let tap =  UITapGestureRecognizer(target: self, action: "actionPressed:")
        actionButton.addGestureRecognizer(tap)
        
        let doubleTap =  UITapGestureRecognizer(target: self, action: "actionDoubleTapped:")
        doubleTap.numberOfTapsRequired = 2
        
        tap.requireGestureRecognizerToFail(doubleTap)
        actionButton.addGestureRecognizer(doubleTap)
        actionButton.selected = true
    }
    
    private func addSlider() {
        opacitySlider.translatesAutoresizingMaskIntoConstraints = false
        opacitySlider.didValueChanged = { value in
            self.imageView.alpha = value
        }
        addSubview(opacitySlider)

        addEqualConstraint(opacitySlider, constant: 0, attribute: .Trailing, parent: self)
        addEqualConstraint(opacitySlider, constant: 20, attribute: .Width, parent: nil)
        addEqualConstraint(opacitySlider, constant: 20, attribute: .Top, parent: self)
        addEqualConstraint(opacitySlider, constant: -20, attribute: .Bottom, parent: self)
    }
    
    private func makeScreenshot() -> UIImage? {
        if let delegate = UIApplication.sharedApplication().delegate, let optionalWindow = delegate.window, let window = optionalWindow {
            UIGraphicsBeginImageContextWithOptions(self.frame.size, self.opaque, 0.0)
            window.layer.renderInContext(UIGraphicsGetCurrentContext()!)
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
        config = PixelPerfectConfig(active : true, imageName : imagesNames[0], grid : false, magnifierCircular : false)
        return config!
    }
}

class CircularButton : UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = min(frame.width, frame.height)/2
        layer.borderColor = UIColor.whiteColor().CGColor
        layer.borderWidth = 2
        layer.masksToBounds = true
    }
}

class Slider : UIView {

    var didValueChanged : ((CGFloat)->())?
    
    convenience init () {
        self.init(frame:CGRect.zero)
        let move =  UIPanGestureRecognizer(target: self, action: "didFingerMoved:")
        addGestureRecognizer(move)
    }
    
    func didFingerMoved(gestureRecognizer:UIGestureRecognizer) {
        let position = gestureRecognizer.locationInView(self)
        if position.x>0 && position.x < frame.width {
            didValueChanged?(1 - position.y / frame.height)
        }
    }
}

class Magnifier : UIView, UIGestureRecognizerDelegate {
    
    private let kGridLinesCount : Int = 8
    private let kAreaSize : CGFloat = 200
    private let kZoom : CGFloat = 3
    
    private let imageView = UIImageView()
    private var showGrid : Bool?
    private var isCircular : Bool?
    
    private var area : CGRect?
    private var imageFrame : CGRect?
    
    private var image : UIImage?
    private var startMovingPoint : CGPoint?
    
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
    
    func setImage(image : UIImage?) {
        if let image = image {
            self.image = image
            self.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        }
        setNeedsDisplay()
    }
    
    func setPoint(point : CGPoint) {
        imageFrame = CGRect(x: -point.x * (kZoom - 1), y: -point.y * (kZoom - 1), width: frame.width * kZoom, height: frame.height * kZoom)
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
        if let area = area {
            
            area.width
            
            setPoint(CGPoint(x: area.origin.x + area.width/2 + frame.origin.x + point.x - startMovingPoint!.x, y: area.origin.y + area.height/2 + frame.origin.y + point.y - startMovingPoint!.y))
            startMovingPoint = point
        }
    }
    
    func endMove() {
        startMovingPoint = nil
    }
     
    func isPointInside(point : CGPoint) -> Bool {
        return area != nil && area!.contains(CGPoint(x: point.x - frame.origin.x, y: point.y - frame.origin.y))
    }
    
    override func drawRect(rect: CGRect) {
        if let area = area, let imageFrame = imageFrame {
            
            let circularPath = isCircular == nil || isCircular! ? UIBezierPath(ovalInRect: area) : UIBezierPath(rect: area)
            circularPath.addClip()
            image?.drawInRect(imageFrame)
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