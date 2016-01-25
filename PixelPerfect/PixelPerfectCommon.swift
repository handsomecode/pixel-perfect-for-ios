import UIKit

class PixelPerfectCommon {
    
    private static let kBundleName = "pixelperfect"
    private static let kBundleExt = "bundle"
    
    class func bundle() -> NSBundle {
        return NSBundle(identifier: "is.handsome.PixelPerfect")!
    }
    
    class func imageByName(name : String) -> UIImage? {
        return UIImage(named: "\(kBundleName).\(kBundleExt)/\(name)")
    }
    
    class func getImagesBundlePath() -> String? {
        if let path = NSBundle.mainBundle().pathForResource(kBundleName, ofType: kBundleExt), let bundle = NSBundle(path: path) {
            return bundle.resourcePath
        }
        return nil
    }
}

extension UIImageView {
    
    func invertImage() {
        if let originalImage = image {
            UIGraphicsBeginImageContextWithOptions(originalImage.size, true, UIScreen.mainScreen().scale)
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), .Copy)
            let imageRect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height)
            originalImage.drawInRect(imageRect)
            
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), .Difference);
            CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),UIColor.whiteColor().CGColor);
            CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, originalImage.size.width, originalImage.size.height));
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
    }
    
    func addDashedBorder() {
        layer.sublayers?.removeAll()
        
        let frameSize = frame.size
        let shapeRect = CGRect(x: -0.5, y: -0.5, width: frameSize.width + 1, height: frameSize.height + 1)
        let color = UIColor.blackColor().CGColor
        
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 0.5
        shapeLayer.lineJoin = kCALineJoinRound
        shapeLayer.lineDashPattern = [6,3]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 0).CGPath
        
        self.layer.addSublayer(shapeLayer)
    }
}