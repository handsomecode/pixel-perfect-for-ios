//
//  PixelPerfectLayout.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 15/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectLayout : PixelPerfectView {
    
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
        
        let doubleTapAndMove =  UIDoubleTapAndMoveGestureRecognizer(target: self, action: "showZoom:")
        addGestureRecognizer(doubleTapAndMove)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("PixelPerfectLayout does not support NSCoding")
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return actionButton.frame.contains(point) || popover != nil ? true : abortTouch
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let firstFinger = touches.first {
            startDraggingPoint = firstFinger.locationInView(self)
        } else {
            startDraggingPoint = nil
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let startDraggingPoint = startDraggingPoint, let firstFinger = touches.first else {
            return
        }
        let currentDraggingPoint = firstFinger.locationInView(self)
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
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isHorizontalDragging = nil
    }
    
    func actionPressed(sender: UIButton!) {
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
        actionButton.center = gestureRecognizer.locationInView(self)
    }
    
    func showZoom(gestureRecognizer:UIGestureRecognizer) {
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
        actionButton.backgroundColor = UIColor.blueColor()
        actionButton.setTitle("PP", forState: .Normal)
        
        actionButton.addTarget(self, action: "actionPressed:", forControlEvents: .TouchUpInside)
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionButton)
        
        addEqualConstraint(actionButton, constant: -10, attribute: .Trailing, parent: self)
        addEqualConstraint(actionButton, constant: -10, attribute: .Bottom, parent: self)
        addEqualConstraint(actionButton, constant: 60, attribute: .Width, parent: nil)
        addEqualConstraint(actionButton, constant: 60, attribute: .Height, parent: nil)
        
        let longPress =  UILongPressGestureRecognizer(target: self, action: "actionLongPress:")
        actionButton.addGestureRecognizer(longPress)
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
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        guard let firstFinger = touches.first else {
            return
        }
        let position = firstFinger.locationInView(self)
        didValueChanged?(1 - position.y / frame.height)
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