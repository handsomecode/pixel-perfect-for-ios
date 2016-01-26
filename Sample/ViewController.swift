import UIKit
import PixelPerfect

class ViewController: UIViewController {

    @IBOutlet weak var labelBottomConstaint: NSLayoutConstraint!
    @IBOutlet weak var ppButton: UIButton!
    
    private let originalBottomConstraint : CGFloat = 20
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
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

