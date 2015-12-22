//
//  PixelPerfectActionButton.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 22/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

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
        
        setState(.PP)
    }
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    
    var selected : Bool! {
        didSet(newValue) {
            if newValue != nil {
                setState(newValue! ? .PP : .APP)
            }
        }
    }
    
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
        xLabel.text = "\(x)"
        yLabel.text = "\(y)"
    }
    
    func setState(state : State) {
        if !xLabel.hidden {
            return
        }
        if state == .PP {
            image.image = UIImage(named: "pp-pp")
        } else if state == .APP {
            image.image = UIImage(named: "pp-app")
        }
    }
}