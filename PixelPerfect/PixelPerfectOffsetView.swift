//
//  PixelPerfectOffsetView.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 12/01/16.
//  Copyright © 2016 Handsome. All rights reserved.
//

import UIKit

class PixelPerfectOffsetView : PixelPerfectView {
    
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    private var layouted = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !layouted {
            frame = CGRect(x: frame.origin.x + frame.size.width / 2 - containerView.frame.size.width / 2, y: frame.origin.y + frame.size.height / 2 - containerView.frame.size.height / 2, width: containerView.frame.size.width, height: containerView.frame.size.height)
            layouted = true
        }
    }
    
    func showOffset(x: Int, y: Int) {
        xLabel.text = "\(x)px"
        yLabel.text = "\(y)px"
    }
}