//
//  ViewController.swift
//  Sample
//
//  Created by Anton Rozhkov on 07/01/16.
//  Copyright © 2016 Handsome. All rights reserved.
//

import UIKit
import PixelPerfect

class ViewController: UIViewController {

    @IBOutlet weak var labelTopConstaint: NSLayoutConstraint!
    
    private let originalTopConstraint : CGFloat = 290
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        labelTopConstaint.constant = originalTopConstraint - 3
        view.layoutIfNeeded()
        let incorrect = PixelPerfectImage(image: makeScreenshot(), imageName: "incorrect")
        labelTopConstaint.constant = originalTopConstraint
        view.layoutIfNeeded()
        let correct = PixelPerfectImage(image: makeScreenshot(), imageName: "correct")
        
        let pixelPerfect = PixelPerfect.Builder(buildClosure: { builder in
            builder.withImages = [incorrect, correct]
            builder.imageDensity = 1
        }).build()
        PixelPerfect.setSingletonInstance(pixelPerfect)
    }

    @IBAction func ppPressed(sender: AnyObject) {
        if PixelPerfect.instance().isShown() {
            PixelPerfect.instance().hide()
        } else {
            PixelPerfect.instance().show()
        }
        
    }
    
    private func makeScreenshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, false, 0)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

