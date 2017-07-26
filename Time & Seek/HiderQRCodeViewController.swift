//
//  HiderQRCodeViewController.swift
//  Timed N Seek
//
//  Created by Patrick Ridd on 6/3/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit

class HiderQRCodeViewController: UIViewController {


    @IBOutlet weak var hiderQRCodeImage: UIImageView!
    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var qrcodeImage: CIImage?
    let uuid = UUID().uuidString

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createQRCode()
        
        self.nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        self.backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        self.backButton.setTitleColor(UIColor.geraldine, for: .normal)

    }
    
    func createQRCode() {
    
        uuidTextField.text = self.uuid
        let data = uuidTextField.text?.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        
        guard let qrcodeImage = filter?.outputImage else { return }
        
        // Reduce blurriness in QR Code
        let scaleX = hiderQRCodeImage.frame.size.width / qrcodeImage.extent.size.width
        let scaleY = hiderQRCodeImage.frame.size.height / qrcodeImage.extent.size.height
        
        let transformedImage = qrcodeImage.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        hiderQRCodeImage.image = UIImage(ciImage: transformedImage)
        uuidTextField.resignFirstResponder()
    }

    
    func nextButtonTapped() {
        SoundsController.sharedController.play(sound: .userTap)
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let hiderVC = storyBoard.instantiateViewController(withIdentifier: "hiderVC") as? HiderViewController else { return }
        hiderVC.uuid = self.uuid
        self.present(hiderVC, animated: true, completion: nil)
        
    }
    
    func backButtonTapped() {
        SoundsController.sharedController.play(sound: .userTap)
        self.dismiss(animated: true, completion: nil)
    }
   
}
