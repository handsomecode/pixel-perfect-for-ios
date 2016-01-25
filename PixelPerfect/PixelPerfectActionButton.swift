import UIKit

class PixelPerfectActionButton : UIView {
    
    enum State {
        case PP
        case APP   
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xLabel.hidden = true
        yLabel.hidden = true
    }
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    
    private var fixedOffsetX = 0
    private var fixedOffsetY = 0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = min(frame.width, frame.height)/2
        layer.borderColor = UIColor.whiteColor().CGColor
        layer.borderWidth = 2
        layer.masksToBounds = true
    }
    
    func setOffset(x: Int, y: Int) {
        image.hidden = true
        xLabel.hidden = false
        yLabel.hidden = false
        updateLabels(x, y: y)
    }
    
    func fixOffset(x: Int, y: Int) {
        fixedOffsetX = x
        fixedOffsetY = y
        updateLabels(x, y: y)
    }
    
    func setState(state : State) {
        if !xLabel.hidden {
            return
        }
        if state == .PP {
            image.image = UIImage(named: "pp-pp", inBundle: PixelPerfectCommon.bundle(), compatibleWithTraitCollection: nil)
        } else if state == .APP {
            image.image = UIImage(named: "pp-app", inBundle: PixelPerfectCommon.bundle(), compatibleWithTraitCollection: nil)
        }
    }
    
    private func updateLabels(x: Int, y: Int) {
        xLabel.text = "\(x - fixedOffsetX)px"
        yLabel.text = "\(y - fixedOffsetY)px"
    }
}