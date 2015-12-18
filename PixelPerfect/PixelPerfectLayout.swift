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
        
        let doubleTapAndMove =  UIDoubleTapAndMoveGestureRecognizer(target: self, action: "showZoom:")
        doubleTapAndMove.delegate = self
        addGestureRecognizer(doubleTapAndMove)
        
        let move =  UIPanGestureRecognizer(target: self, action: "moveImage:")
        doubleTapAndMove.delegate = self
        imageView.addGestureRecognizer(move)
        
        let tap =  UITapGestureRecognizer(target: self, action: "moveAfterTap:")
        imageView.addGestureRecognizer(tap)
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
        popover.restore(config)
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
    
    func actionLongPress(gestureRecognizer:UIGestureRecognizer) {
        if popover != nil {
            return
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
        if gestureRecognizer.state == .Began {
            magnifier = Magnifier()
            magnifier!.setImage(makeScreenshot())
            magnifier!.setPoint(gestureRecognizer.locationInView(self))
            addSubview(magnifier!)
        } else if gestureRecognizer.state == .Ended || gestureRecognizer.state == .Failed {
            magnifier?.removeFromSuperview()
        } else {
            magnifier?.setPoint(gestureRecognizer.locationInView(self))
        }
    }
    
    func moveImage(gestureRecognizer:UIGestureRecognizer) {
        if popover != nil {
            return
        }
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
                imageView.center.x += currentDraggingPoint.x - startDraggingPoint.x
            } else {
                imageView.center.y += currentDraggingPoint.y - startDraggingPoint.y
            }
            self.startDraggingPoint = currentDraggingPoint
        }
    }
    
    func moveAfterTap(gestureRecognizer:UIGestureRecognizer) {
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
        actionButton.setImage(UIImage(named: "handsome-logo"), forState: .Normal)
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

class Magnifier : UIView {
    
    private let kZoom : CGFloat = 2
    private let imageView = UIImageView()
    
    private var area : CGRect?
    private var imageFrame : CGRect?
    
    private var image : UIImage?
    
    convenience init () {
        self.init(frame:CGRect.zero)
        backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        opaque = false;
    }
    
    func setImage(image : UIImage?) {
        if let image = image {
            self.image = image
            self.frame = CGRect(x: -image.size.width * (kZoom - 1) / 2, y: -image.size.height * (kZoom - 1) / 2, width: image.size.width * kZoom, height: image.size.height * kZoom)
        }
        setNeedsDisplay()
    }
    
    func setPoint(point : CGPoint) {
        imageFrame = CGRect(x: -point.x * (kZoom - 1) - frame.origin.x, y: -point.y * (kZoom - 1) - frame.origin.y, width: frame.width, height: frame.height)
        area = CGRect(x: point.x - 50 - frame.origin.x, y: point.y - 50 - frame.origin.y, width: 100, height: 100)
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        if let area = area, let imageFrame = imageFrame {
            let circularPath = UIBezierPath(ovalInRect: area)
            circularPath.addClip()
            UIColor.whiteColor().setFill()
            image?.drawInRect(imageFrame)
            circularPath.stroke()
        }
    }
}