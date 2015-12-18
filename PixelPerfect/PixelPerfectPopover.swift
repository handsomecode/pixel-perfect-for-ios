//
//  PixelPerfectPopover.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 16/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectPopover : PixelPerfectView, UIPickerViewDelegate, UIPickerViewDataSource  {
    
    var didClose : ((PixelPerfectConfig) -> ())?

    @IBOutlet weak var namesPicker: UIPickerView!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var gridSwitch: UISwitch!
    @IBOutlet weak var magnifierShapeSegmentedControl: UISegmentedControl!
    
    private var imagesNames : [String]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 6.0
        self.layer.masksToBounds = false
    }
    
    func setImageNames(imagesNames : [String]) {
        self.imagesNames = imagesNames
        namesPicker.delegate = self
        namesPicker.dataSource = self
    }
    
    func restore(config : PixelPerfectConfig?) {
        if let config = config {
            activeSwitch.on = config.active
            namesPicker.selectRow(imagesNames.indexOf(config.imageName)!, inComponent: 0, animated: false)
            gridSwitch.on = config.grid
            magnifierShapeSegmentedControl.selectedSegmentIndex = config.magnifierCircular ? 0 : 1
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return imagesNames.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return imagesNames[row]
    }
    
    @IBAction func closePressed(sender: AnyObject) {
        let config = PixelPerfectConfig(active: activeSwitch.on, imageName: imagesNames[namesPicker.selectedRowInComponent(0)], grid: gridSwitch.on, magnifierCircular : magnifierShapeSegmentedControl.selectedSegmentIndex == 0)
        didClose?(config)
    }
}