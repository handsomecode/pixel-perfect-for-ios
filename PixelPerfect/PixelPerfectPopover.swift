import UIKit

class PixelPerfectPopover : PixelPerfectView  {
    
    var didClose : ((PixelPerfectConfig) -> ())?
    var didFixOffset : (() -> ())?
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var imageNameLabel: UILabel!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var inverseSwitch: UISwitch!
    @IBOutlet weak var opacityView: UIView!
    @IBOutlet weak var opacitySlider: UISlider!
    @IBOutlet weak var offsetLabel: UILabel!
    
    private var imagesNames : [String]!
    private var pixelPerfectImages : [PixelPerfectImage]!
    private var config : PixelPerfectConfig!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 6.0
        self.layer.masksToBounds = false
        
        opacitySlider.minimumValue = 0.05
        opacitySlider.maximumValue = 0.95
        
        setupCollectionView()
    }
    
    func setImages(imagesNames : [String], pixelPerfectImages : [PixelPerfectImage]) {
        self.imagesNames = imagesNames
        self.pixelPerfectImages = pixelPerfectImages
    }
    
    func restore(config : PixelPerfectConfig?) {
        if let config = config {
            self.config = config
            imageNameLabel.text = config.imageName
            opacitySlider.value = Float(config.opacity)
            opacityView.alpha = config.opacity
            inverseSwitch.on = config.inverse
            setOffset(config.offsetX, y: config.offsetY)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    
    @IBAction func closePressed(sender: AnyObject) {
        config.inverse = inverseSwitch.on
        config.opacity = CGFloat(opacitySlider.value)
        didClose?(config)
    }
    
    @IBAction func backPressed(sender: AnyObject) {
        imagesCollectionView.hidden = true
        backButton.hidden = true
        closeButton.hidden = false
    }
    
    @IBAction func changeImagePressed(sender: AnyObject) {
        backButton.hidden = false
        closeButton.hidden = true
        imagesCollectionView.hidden = false
    }
    
    @IBAction func fixPressed(sender: AnyObject) {
        didFixOffset?()
        setOffset(0, y: 0)
    }
    
    @IBAction func opacityChanged(sender: AnyObject) {
        opacityView.alpha = CGFloat((sender as! UISlider).value)
    }
    
    @IBAction func inverseChanged(sender: AnyObject) {
        if (sender as! UISwitch).on {
            opacitySlider.value = 0.5
            opacityChanged(opacitySlider)
        }
    }
    
    private func setOffset(x: Int, y: Int) {
        offsetLabel.text = "(\(x)px, \(y)px)"
    }
}

extension PixelPerfectPopover : UICollectionViewDataSource {
    
    func setupCollectionView() {
        imagesCollectionView.registerNib(UINib(nibName: "PixelPerfectItemViewCell", bundle: PixelPerfectCommon.bundle()), forCellWithReuseIdentifier: "albumItem")
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pixelPerfectImages.count > 0 ? pixelPerfectImages.count : imagesNames.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("albumItem", forIndexPath: indexPath) as! PixelPerfectItemViewCell
        var image : UIImage!
        var name : String!
        if pixelPerfectImages.count > 0 {
            image = pixelPerfectImages[indexPath.row].image
            name = pixelPerfectImages[indexPath.row].imageName
        } else {
            image = PixelPerfectCommon.imageByName(imagesNames[indexPath.row])
            name = imagesNames[indexPath.row]
        }
        cell.setup(image, label: name)
        return cell
    }
}

extension PixelPerfectPopover : UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let bigSize = max(frame.width, frame.height)
        let smallSize = min(frame.width, frame.height)
        let width = (smallSize - 100 ) / 3
        return CGSize(width: width, height: bigSize / smallSize * width)
    }
}

extension PixelPerfectPopover : UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let imageName = pixelPerfectImages.count > 0 ? pixelPerfectImages[indexPath.row].imageName : imagesNames[indexPath.row]
        imageNameLabel.text = imageName
        config.imageName = imageName
        closePressed(self)
    }
}