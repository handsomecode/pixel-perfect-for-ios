//
//  PixelPerfectLayout.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 15/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectLayout : PixelPerfectView, UIGestureRecognizerDelegate {
    
    private static let kBundleName = "pixelperfect"
    private static let kBundleExt = "bundle"
    private let kMicroPositioningOffset : CGFloat = 7
    private let kMicroPositioningFactor : CGFloat = 7
    
    private let imageView = UIImageView()
    private var actionButton : PixelPerfectActionButton!
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
        
        if let bundlePath = PixelPerfectLayout.getBundlePath() {
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
        
        let move =  UIPanGestureRecognizer(target: self, action: "moveImage:")
        move.delegate = self
        addGestureRecognizer(move)
        
        let doubleTapAndWait =  UIDoubleTapAndWaitGestureRecognizer(target: self, action: "resetPosition:")
        addGestureRecognizer(doubleTapAndWait)
        
        let tap =  UITapGestureRecognizer(target: self, action: "showZoom:")
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        tap.requireGestureRecognizerToFail(doubleTapAndWait)
        addGestureRecognizer(tap)
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
            self.actionButton.setState(pixelPerfectConfig.active ? .PP : .APP)
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
        actionButton.setState(abortTouch ? .PP : .APP)
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
    
    func resetPosition(gestureRecognizer:UIPanGestureRecognizer) {
        if gestureRecognizer.state == .Ended {
            actionButton.fixOffset(-Int(imageView.frame.origin.x * UIScreen.mainScreen().scale), y: -Int(imageView.frame.origin.y * UIScreen.mainScreen().scale))
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
            
            actionButton.setOffset(-Int(imageView.frame.origin.x * UIScreen.mainScreen().scale), y: -Int(imageView.frame.origin.y * UIScreen.mainScreen().scale))
            
            if let magnifier = magnifier {
                magnifier.hidden = true
                actionButton.hidden = true
                magnifier.setImage(makeScreenshot())
                magnifier.hidden = false
                actionButton.hidden = false
            }
        }
    }
    
    private func setImage(name : String) {
        if name == currentImage {
            return
        }
        currentImage = name
        if let delegate = UIApplication.sharedApplication().delegate, let optionalWindow = delegate.window, let window = optionalWindow {
            let image = PixelPerfectLayout.imageByName(name)!
            let ratio = image.size.height / image.size.width
            let frame = CGRect(x: 0, y: 0, width: window.frame.width, height: window.frame.width * ratio)
            imageView.frame = frame
            imageView.image = image
        }
    }
    
    class func imageByName(name : String) -> UIImage? {
        return UIImage(named: "\(kBundleName).\(kBundleExt)/\(name)")!
    }
    
    class func getBundlePath() -> String? {
        if let path = NSBundle.mainBundle().pathForResource(kBundleName, ofType: kBundleExt), let bundle = NSBundle(path: path) {
            return bundle.resourcePath
        }
        return nil
    }
    
    private func addActionButton() {
        actionButton = NSBundle.mainBundle().loadNibNamed("PixelPerfectActionButton", owner: self, options: nil).first as! PixelPerfectActionButton
        
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
        actionButton.setState(.PP)
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
        
        if let area = area, imageFrame = imageFrame {
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
            self.imageFrame?.offsetInPlace(dx: imagedx, dy: imagedy)
            
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