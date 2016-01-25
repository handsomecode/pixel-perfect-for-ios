import Foundation

public struct PixelPerfectImage {
    public let image : UIImage
    public let imageName : String
    
    public init(image : UIImage, imageName : String) {
        self.image = image
        self.imageName = imageName
    }
}
