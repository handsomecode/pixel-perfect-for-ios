//
//  PixelPerfectView.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 16/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectView : UIView {
    
    func addEqualConstraint(view : UIView, constant : CGFloat, attribute : NSLayoutAttribute, parent : UIView?) -> NSLayoutConstraint{
        let constraint = NSLayoutConstraint(item: view, attribute: attribute, relatedBy: NSLayoutRelation.Equal, toItem: parent, attribute: parent == nil ? NSLayoutAttribute.NotAnAttribute : attribute, multiplier: 1, constant: constant)
        addConstraint(constraint)
        return constraint
    }
}