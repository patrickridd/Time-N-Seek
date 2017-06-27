//
//  SeekerQRScanViewController.swift
//  Timed N Seek
//
//  Created by Patrick Ridd on 6/3/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit
import AVFoundation

class SeekerQRScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var seekerLabel: UILabel!
    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var uuid: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        AppUtility.lockOrientation(.portrait)
        nextButton.setTitleColor(UIColor.gray, for: .normal)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.setTitleColor(UIColor.geraldine, for: .normal)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupQRReader()
    }
    
    func nextButtonTapped() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let seekerVC = storyBoard.instantiateViewController(withIdentifier: "seekerVC") as? SeekerViewController else { return }
        
        seekerVC.uuid = self.uuid
        seekerVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen;
        self.present(seekerVC, animated: true, completion: nil)
    }
    
    func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupQRReader() {
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode,AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeAztecCode, AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeCode93Code]
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            if let videoLayer = videoPreviewLayer {
                view.layer.addSublayer(videoLayer)
                captureSession?.startRunning()
                view.bringSubview(toFront: topView)
                view.bringSubview(toFront: bottomView)
            }
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.myBlue.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }

        
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            uuidTextField.text = "No QR code is detected".localized
            uuidTextField.textColor = UIColor.gray
            nextButton.setTitleColor(UIColor.gray, for: .normal)
//           nextButton.isEnabled = false
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                self.captureSession?.stopRunning()
                self.uuid = metadataObj.stringValue
                uuidTextField.text = metadataObj.stringValue
                uuidTextField.textColor = UIColor.myBlue
                nextButton.setTitleColor(UIColor.myBlue, for: .normal)
                nextButtonTapped()
                nextButton.isEnabled = true
            }
        }
    }


   
}
