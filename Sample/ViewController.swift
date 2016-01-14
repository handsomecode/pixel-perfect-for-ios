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

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func ppPressed(sender: AnyObject) {
        if PixelPerfectController.isShown() {
            PixelPerfectController.hide()
        } else {
            PixelPerfectController.show()
        }
    }
}

