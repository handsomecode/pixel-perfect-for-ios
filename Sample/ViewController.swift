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
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func ppPressed(sender: AnyObject) {
        if PixelPerfectController.isShown() {
            PixelPerfectController.hide()
        } else {
            PixelPerfectController.show()
        }
    }
}

