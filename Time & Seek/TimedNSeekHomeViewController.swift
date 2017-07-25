//
//  TimedNSeekHomeViewController.swift
//  Timed N Seek
//
//  Created by Patrick Ridd on 5/31/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit
import CoreBluetooth

class TimedNSeekHomeViewController: UIViewController, CBPeripheralManagerDelegate {

    @IBOutlet weak var hiderButton: UIButton!
    @IBOutlet weak var seekerButton: UIButton!
    @IBOutlet weak var turnOnBluetoothButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    var peripheralManager: CBPeripheralManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateButtons()
        loadAnimation()
        peripheralManager = CBPeripheralManager(delegate: self as CBPeripheralManagerDelegate, queue: nil, options: nil)
    }
    
    func loadAnimation() {
        hiderButton.alpha = 0
        seekerButton.alpha = 0
        UIView.animate(withDuration: 1.0, animations: {
            self.hiderButton.alpha = 1.0
            self.seekerButton.alpha = 1.0
            SoundsController.sharedController.play(sound: .gameLoads)
        })

    }
    func updateButtons() {
        hiderButton.layer.borderColor = UIColor.myBlue.cgColor
        seekerButton.layer.borderColor = UIColor.myBlue.cgColor
        hiderButton.layer.borderWidth = 1.0
        seekerButton.layer.borderWidth = 1.0
        
        seekerButton.addTarget(self, action: #selector(didTapSeekerButton), for: .touchUpInside)
        hiderButton.addTarget(self, action: #selector(didTapHiderButton), for: .touchUpInside)
        turnOnBluetoothButton.addTarget(self, action: #selector(didTapBluetoothButton), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
    }
    
    // MARK: Button Actions
    
    func didTapSeekerButton() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let seekerVC = storyboard.instantiateViewController(withIdentifier: "seekerQRReaderVC")
        self.present(seekerVC, animated: true, completion: nil)
    }
    
    func didTapHiderButton() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let hiderVC = storyboard.instantiateViewController(withIdentifier: "hiderQRCodeVC")
        self.present(hiderVC, animated: true, completion: nil)
    }
    
    func didTapBluetoothButton() {
        guard let url = URL(string: "App-Prefs:root=Bluetooth") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func didTapSettings() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let hiderVC = storyboard.instantiateViewController(withIdentifier: "settingsViewController")
        self.present(hiderVC, animated: true, completion: nil)
    }
    
    // MARK: CBPeripheralManagerDelegate methods
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            self.turnOnBluetoothButton.isEnabled = false
            self.turnOnBluetoothButton.isHidden = true
        case .poweredOff:
            self.turnOnBluetoothButton.isEnabled = true
            self.turnOnBluetoothButton.isHidden = false
        case .resetting: break
        case .unauthorized: break
        case .unsupported: break
        case .unknown: break
            
        }
    }

}


