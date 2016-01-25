import UIKit

class PixelPerfectItemViewCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    func setup(image : UIImage?, label : String) {
        self.image.image = image
        self.label.text = label
    }
    
}