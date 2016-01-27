import UIKit

class PixelPerfectLayout : PixelPerfectView, UIGestureRecognizerDelegate {
    
    private let kMicroPositioningOffset : CGFloat = 5
    private let kOverlayMinimumVisibleSize : CGFloat = 50
    
    private var imagesNames : [String]!
    private var currentImage : String = ""
    
    private var pixelPerfectImages : [PixelPerfectImage]!
    private var currentImagePosition : Int?
    
    private var startDraggingPoint : CGPoint? = nil
    private var startOpacityPoint : CGPoint? = nil
    private var startOpacityValue : CGFloat!
    private var isHorizontalDragging : Bool? = nil
    private var fixedOverlayOffset = CGPoint(x: 0, y: 0)
    private var inverse = false
    private var actionButtonTrailing : NSLayoutConstraint!
    private var actionButtonBottom : NSLayoutConstraint!
    
    private let imageView = UIImageView()
    private var popover : PixelPerfectPopover!
    private var magnifier : PixelPerfectMagnifier?
    private var offsetView : PixelPerfectOffsetView?

    private var microOffsetDx : CGFloat = 0
    private var microOffsetDy : CGFloat = 0
    
    private var imageDensity : CGFloat!
    
    init(config : PixelPerfectBuilderConfig, frame : CGRect) {
        super.init(frame : frame)
        
        autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        imageDensity = config.imageDensity
        
        if let images = config.withImages {
            self.pixelPerfectImages = images
            self.imagesNames = []
        } else {
            self.pixelPerfectImages = []
            if !loadFromBundle(config.withBundle) && !loadFromBundle(PixelPerfectCommon.getImagesBundlePath()) {
                self.imagesNames = []
            }
        }
        if pixelPerfectImages.count > 0 {
            setImageWithNameOrDefault(config.image, defaultName: pixelPerfectImages[0].imageName)
        } else if imagesNames.count > 0 {
            setImageWithNameOrDefault(config.image, defaultName: imagesNames[0])
        }
        
        if let inverse = config.inverse {
            if inverse {
                self.inverse = true
                imageView.invertImage()
            }
        }
        
        if let transparency = config.transparency {
            imageView.alpha = CGFloat(transparency)
        } else {
            imageView.alpha = 0.5
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
    
    func overlayTapped(gestureRecognizer:UIGestureRecognizer) {
        if popover != nil {
            return
        }
        if hideMagnifierIfNeeded() {
            return
        }
        popover = PixelPerfectCommon.bundle().loadNibNamed("PixelPerfectPopover", owner: self, options: nil).first as! PixelPerfectPopover
        popover.setImages(imagesNames, pixelPerfectImages: pixelPerfectImages)
        popover.restore(getConfig())
        popover.didClose = { pixelPerfectConfig in
            let imageChanged = self.setImage(pixelPerfectConfig.imageName)
            self.imageView.alpha = pixelPerfectConfig.opacity
            if self.inverse != pixelPerfectConfig.inverse {
                self.inverse = pixelPerfectConfig.inverse
                if !imageChanged {
                    self.imageView.invertImage()
                }
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
    
    func handleTripleTap(gestureRecognizer: UITripleTapGestureRecognizer) {
        if gestureRecognizer.state == .Ended {
            inverse = !inverse
            imageView.invertImage()
        }
    }
    
    func resetPosition(gestureRecognizer:UIDoubleTapAndWaitGestureRecognizer) {
        if gestureRecognizer.state == .Ended {
            if gestureRecognizer.isSecondJustTap {
                inverse = !inverse
                imageView.invertImage()
            } else {
            fixedOverlayOffset = CGPoint(x: Int(imageView.frame.origin.x * UIScreen.mainScreen().scale), y: Int(imageView.frame.origin.y * UIScreen.mainScreen().scale))
            }
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
            addSubview(offsetView!)
            updateOffsetView(gestureRecognizer.locationInView(self))
            
            startDraggingPoint = nil
            microOffsetDx = 0
            microOffsetDy = 0
        } else if gestureRecognizer.state == .Ended || gestureRecognizer.state == .Failed {
            offsetView?.removeFromSuperview()
            offsetView = nil
            startDraggingPoint = nil
            isHorizontalDragging = nil
            microOffsetDx = 0
            microOffsetDy = 0
        } else if gestureRecognizer.state == .Changed {
            if startDraggingPoint ==  nil {
                updateOffsetView(gestureRecognizer.locationInView(self))
                startDraggingPoint = gestureRecognizer.locationInView(self)
                return
            }
            guard let startDraggingPoint = startDraggingPoint else {
                return
            }
            let currentDraggingPoint = gestureRecognizer.locationInView(self)
            if isHorizontalDragging == nil {
                isHorizontalDragging = abs(currentDraggingPoint.x - startDraggingPoint.x) > abs(currentDraggingPoint.y - startDraggingPoint.y)
            }
            if isHorizontalDragging! {
                var dx = currentDraggingPoint.x - startDraggingPoint.x
                if abs(dx) < kMicroPositioningOffset {
                    microOffsetDx += dx / (kMicroPositioningOffset)
                    dx = round(microOffsetDx) / UIScreen.mainScreen().scale
                    if dx != 0 {
                        microOffsetDx = 0;
                    }
                } else {
                    microOffsetDx = 0;
                }
                if imageView.frame.origin.x + imageView.frame.size.width + dx < kOverlayMinimumVisibleSize {
                   imageView.frame.origin.x = kOverlayMinimumVisibleSize - imageView.frame.size.width
                } else if imageView.frame.origin.x + dx > frame.size.width - kOverlayMinimumVisibleSize {
                   imageView.frame.origin.x = frame.size.width - kOverlayMinimumVisibleSize
                } else {
                    imageView.center.x += dx
                }
            } else {
                var dy = currentDraggingPoint.y - startDraggingPoint.y
                if abs(dy) < kMicroPositioningOffset {
                    microOffsetDy += dy / (kMicroPositioningOffset)
                    dy = round(microOffsetDy) / UIScreen.mainScreen().scale
                    if dy != 0 {
                        microOffsetDy = 0;
                    }
                } else {
                    microOffsetDy = 0;
                }
                if imageView.frame.origin.y + imageView.frame.size.height + dy < kOverlayMinimumVisibleSize {
                    imageView.frame.origin.y = kOverlayMinimumVisibleSize - imageView.frame.size.height
                } else if imageView.frame.origin.y + dy > frame.size.height - kOverlayMinimumVisibleSize {
                    imageView.frame.origin.y = frame.size.height - kOverlayMinimumVisibleSize
                } else {
                    imageView.center.y += dy
                }
            }
            self.startDraggingPoint = currentDraggingPoint
            self.updateOffsetView(gestureRecognizer.locationInView(self))
            
            if let magnifier = magnifier {
                magnifier.setOverlayOffset(imageView.frame.origin.x, dy: imageView.frame.origin.y)
            }
        }
    }
    
    func setImage(name : String) -> Bool {
        if name == currentImage {
            return false
        }
        if pixelPerfectImages.count > 0 {
            for image in pixelPerfectImages {
                if image.imageName == name {
                    return setImage(image.image, name: image.imageName)
                }
            }
        }
        return setImage(PixelPerfectCommon.imageByName(name), name: name)
    }
    
    private func setImage(image: UIImage?, name : String) -> Bool {
        if let image = image {
            currentImage = name
            let frame = CGRect(x: 0, y: 0, width: image.size.width / imageDensity, height: image.size.height / imageDensity)
            imageView.frame = frame
            imageView.image = image
            imageView.addDashedBorder()
            return true
        }
        return false
    }
    
    private func setImageWithNameOrDefault(name : String?, defaultName : String) {
        if let name = name {
            if !setImage(name) {
                setImage(defaultName)
            }
        } else {
            setImage(defaultName)
        }
    }
    
    private func loadFromBundle(bundlePath : String?) -> Bool {
        if let bundlePath = bundlePath {
            do {
                imagesNames = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(bundlePath)
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    private func addImageView() {
        addSubview(imageView)
        imageView.userInteractionEnabled = true
    }
    
    private func addGestureRecognizers() {
        
        let doubleTapAndWait =  UIDoubleTapAndWaitGestureRecognizer(target: self, action: "resetPosition:")
        imageView.addGestureRecognizer(doubleTapAndWait)

        let tap =  UITapGestureRecognizer(target: self, action: "overlayTapped:")
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
        offsetView?.showOffset(-Int(round(imageView.frame.origin.x * UIScreen.mainScreen().scale - fixedOverlayOffset.x)), y: -Int(round(imageView.frame.origin.y * UIScreen.mainScreen().scale - fixedOverlayOffset.y)))
        offsetView?.center = CGPoint(x: fingerPosition.x, y: fingerPosition.y - 50)
    }
}