//
//  ViewController.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 11/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func ppPressed(sender: AnyObject) {
        if PixelPerfectController.isShown() {
            PixelPerfectController.hide()
        } else {
            PixelPerfectController.show()
        }
    }
}

