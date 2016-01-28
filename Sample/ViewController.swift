import UIKit
import PixelPerfect

class ViewController: UIViewController {

    @IBOutlet weak var labelBottomConstaint: NSLayoutConstraint!
    @IBOutlet weak var ppButton: UIButton!
    @IBOutlet weak var imageContainer: UIView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let originalBottomConstraint = 0.2 * imageContainer.frame.size.height
        ppButton.layer.cornerRadius = 4
        ppButton.layer.borderWidth = 1
        ppButton.layer.borderColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1).CGColor
        ppButton.hidden = true
        labelBottomConstaint.constant = originalBottomConstraint + 3
        view.layoutIfNeeded()
        let incorrect = PixelPerfectImage(image: makeScreenshot(), imageName: "incorrect")
        labelBottomConstaint.constant = originalBottomConstraint
        view.layoutIfNeeded()
        let correct = PixelPerfectImage(image: makeScreenshot(), imageName: "correct")

        let pixelPerfect = PixelPerfect.Builder(buildClosure: { builder in
            builder.withImages = [incorrect, correct]
            builder.imageDensity = 1
        }).build()
        ppButton.hidden = false
        PixelPerfect.setSingletonInstance(pixelPerfect)
    }

    @IBAction func ppPressed(sender: AnyObject) {
        if PixelPerfect.instance().isShown() {
            ppButton.setTitle("Show", forState: .Normal)
            PixelPerfect.instance().hide()
        } else {
            ppButton.setTitle("Hide", forState: .Normal)
            PixelPerfect.instance().show()
        }
    }
    
    private func makeScreenshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, true, 0.0)
        view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates : true)
        let screen = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screen
    }
}

