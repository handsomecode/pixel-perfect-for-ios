import UIKit

public class PixelPerfect {
    
    private static var inst : PixelPerfect! = nil
    
    private var shown = false
    private var pixelPerfectLayout : PixelPerfectLayout!
    private var pixelPerfectBuilderConfig : PixelPerfectBuilderConfig
    
    public static func instance() -> PixelPerfect {
        if inst == nil {
            inst = PixelPerfect(pixelPerfectBuilderConfig: createDefaultConfig())
        }
        return inst!
    }
    
    public static func setSingletonInstance(instance: PixelPerfect) {
        if inst == nil {
            inst = instance
            return
        }
        let wasShown = inst.shown
        inst = instance
        if wasShown {
            inst.show()
        }
    }
    
    private static func createDefaultConfig() -> PixelPerfectBuilderConfig {
        var config = PixelPerfectBuilderConfig()
        config.image = nil
        config.inverse = false
        config.transparency = 0.5
        config.withImages = nil
        config.withBundle = nil
        config.imageDensity = UIScreen.mainScreen().scale
        return config
    }
    
    private init(pixelPerfectBuilderConfig : PixelPerfectBuilderConfig) {
        self.pixelPerfectBuilderConfig = pixelPerfectBuilderConfig
    }
    
    public func isShown() -> Bool {
        if let window = UIApplication.sharedApplication().delegate!.window, let views = window?.subviews, let pixelPerfectLayout = pixelPerfectLayout {
            return views.contains(pixelPerfectLayout)
        }
        return false
    }
    
    public func show(name : String? = nil) {
        if let window = UIApplication.sharedApplication().delegate!.window {
            if pixelPerfectLayout == nil {
                pixelPerfectLayout = PixelPerfectLayout(config: pixelPerfectBuilderConfig, frame: window!.frame)
            }
            if let name = name {
                pixelPerfectLayout.setImage(name)
            }
            window!.addSubview(pixelPerfectLayout)
        }
    }
    
    public func hide() {
        if let pixelPerfectView = pixelPerfectLayout {
            pixelPerfectView.removeFromSuperview()
        }
    }
    
    public func destroy() {
        if shown {
            shown = false
            hide()
        }
        pixelPerfectLayout = nil
    }
    
    public class Builder {
        
        public var image: String?
        public var inverse: Bool?
        public var transparency: Float?
        public var withImages: [PixelPerfectImage]?
        public var withBundle: String?
        public var imageDensity: CGFloat?
        
        public typealias BuilderClosure = (Builder) -> ()
        
        public init(buildClosure: BuilderClosure) {
            buildClosure(self)
        }
        
        public func build() -> PixelPerfect {
            var config = PixelPerfect.createDefaultConfig()
            if let image = image {
                config.image = image
            }
            if let inverse = inverse {
                config.inverse = inverse
            }
            if let transparency = transparency {
                config.transparency = transparency
            }
            if let withImages = withImages {
                config.withImages = withImages
            }
            if let withBundle = withBundle {
                config.withBundle = withBundle
            }
            if let imageDensity = imageDensity {
                config.imageDensity = imageDensity
            }
            return PixelPerfect(pixelPerfectBuilderConfig: config)
        }
    }
}


