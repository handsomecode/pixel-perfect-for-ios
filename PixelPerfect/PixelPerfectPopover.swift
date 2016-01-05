//
//  PixelPerfectPopover.swift
//  PixelPerfect
//
//  Created by Anton Rozhkov on 16/12/15.
//  Copyright © 2015 Farecompare. All rights reserved.
//

import UIKit

class PixelPerfectPopover : PixelPerfectView  {
    
    var didClose : ((PixelPerfectConfig) -> ())?

    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var gridSwitch: UISwitch!
    @IBOutlet weak var magnifierShapeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var imageNameLabel: UILabel!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    
    private var imagesNames : [String]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 6.0
        self.layer.masksToBounds = false
        
        setupCollectionView()
    }
    
    func setImageNames(imagesNames : [String]) {
        self.imagesNames = imagesNames
    }
    
    func restore(config : PixelPerfectConfig?) {
        if let config = config {
            activeSwitch.on = config.active
            gridSwitch.on = config.grid
            imageNameLabel.text = config.imageName
            magnifierShapeSegmentedControl.selectedSegmentIndex = config.magnifierCircular ? 0 : 1
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    
    @IBAction func closePressed(sender: AnyObject) {
        if imagesCollectionView.hidden == false {
            imagesCollectionView.hidden = true
            return
        }
        let config = PixelPerfectConfig(active: activeSwitch.on, imageName: imageNameLabel.text!, grid: gridSwitch.on, magnifierCircular : magnifierShapeSegmentedControl.selectedSegmentIndex == 0)
        didClose?(config)
    }
    
    @IBAction func changeImagePressed(sender: AnyObject) {
        imagesCollectionView.hidden = false
    }
}

extension PixelPerfectPopover : UICollectionViewDataSource {
    
    func setupCollectionView() {
        imagesCollectionView.registerNib(UINib(nibName: "PixelPerfectItemViewCell", bundle: nil), forCellWithReuseIdentifier: "albumItem")
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesNames.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("albumItem", forIndexPath: indexPath) as! PixelPerfectItemViewCell
        cell.setup(PixelPerfectLayout.imageByName(imagesNames[indexPath.row]), label: imagesNames[indexPath.row])
        return cell
    }
}

extension PixelPerfectPopover : UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
}

extension PixelPerfectPopover : UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        imageNameLabel.text = imagesNames[indexPath.row]
        imagesCollectionView.hidden = true
    }
}