//
//  HiderViewController.swift
//  Timed N Seek
//
//  Created by Patrick Ridd on 5/31/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import AudioToolbox

class HiderViewController: UIViewController, CBPeripheralManagerDelegate, CLLocationManagerDelegate {

    var beaconRegion: CLBeaconRegion!
    var hiderBeacon: CLBeaconRegion!
    var locationManager: CLLocationManager!
    var peripheralManager: CBPeripheralManager!
    
    var uuid: String?
    let minor = "123"
    let major = "123"
    
    var isSearching: Bool = false
    var isBroadcasting = false
    var dataDictionary = [String: Any]()
    
    @IBOutlet weak var hideButton:UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var hideThenTapLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        peripheralManager = CBPeripheralManager(delegate: self as CBPeripheralManagerDelegate, queue: nil, options: nil)
        
            guard let _ = self.uuid else {
            showAlert(title: "Incomplete Beacon Information".localized, message: "Generate new QR Code and try again".localized)
            return
        }
        
        
        hideButton.layer.borderColor = UIColor.myBlue.cgColor
        hideButton.layer.borderWidth = 1.0
        backButton.setTitleColor(UIColor.geraldine, for: .normal)

        loadingAnimation()
    }
    
    func loadingAnimation() {
        disableHideButton()
        hideButton.alpha = 0.0
        hideThenTapLabel.alpha = 0.0
        UIView.animate(withDuration: 2.0) {
            self.hideThenTapLabel.alpha = 1.0
        }
        self.enableHideButton()
        delayWithSeconds(2) {
            self.hideThenTapLabel.isHidden = true
            UIView.animate(withDuration: 1.5, animations: {
                self.hideButton.alpha = 1.0
            })
            

        //self.resetGame()
        }
    }

    
    
    // MARK: Main
    
    func checkBroadcastState() {
        if !isBroadcasting {
            // Attempt to broadcast
            switch peripheralManager.state {
            case .poweredOn:
                self.startAdvertising()
                self.updateButtonAndBeaconStatus()
            case .poweredOff:
                break
            case .unauthorized:
                break
            case .resetting:
                break
            case .unknown:
                break
            case .unsupported:
                break
            }
        } else {
            // Stop broadcasting
            peripheralManager.stopAdvertising()
            isBroadcasting = false
            self.updateButtonAndBeaconStatus()
        }
    }
    
    func createBeaconRegion() -> CLBeaconRegion? {
        guard let uuidString = self.uuid, let uuid = UUID(uuidString: uuidString), let major = Int(self.major), let minor = Int(self.minor)
            else { return nil }
        return CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(major), minor: CLBeaconMinorValue(minor), identifier: "com.PatrickRidd.Timed-N-Seek-Hider")
        
    }
    
    func startAdvertising() {
        hiderBeacon = self.createBeaconRegion()
        guard let dataDictionary = hiderBeacon.peripheralData(withMeasuredPower: nil) as? [String: Any] else {
            showAlert(title: "Error Connecting".localized, message: "We are having trouble signaling the device. Please try again.".localized)
            isBroadcasting = false
            return
        }
        
        peripheralManager.startAdvertising(dataDictionary)
        isBroadcasting = true
    }
    
    func updateButtonAndBeaconStatus() {
        if isBroadcasting {
            self.hideButton.setTitle("Hiding".localized, for: .normal)
            self.hideButton.layer.borderColor = UIColor.goGreen.cgColor
            self.hideButton.setTitleColor(UIColor.goGreen, for: .normal)
        } else {
            self.hideButton.setTitle("Hide".localized, for: .normal)
            self.hideButton.layer.borderColor = UIColor.myBlue.cgColor
            self.hideButton.setTitleColor(UIColor.myBlue, for: .normal)
        }
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            break
        case .poweredOff:
            self.presentBlueToothNotEnabled()
        case .resetting:
            break
        case .unauthorized:
            break
        case .unsupported:
            break
        case .unknown:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        peripheral.setDesiredConnectionLatency(.low, for: request.central)
    }
    
    
    // MARK: Actions
    
    @IBAction func startButtonPressed(sender:Any){
        guard let _ = self.uuid else {
            showAlert(title: "Incomplete Information".localized, message: "Please complete the Beacon uuid text fields".localized)
            return
        }
        resetStatusLabel()
        checkBroadcastState()
        if !isSearching {
            self.toggleDiscovery()
        }
        
        isSearching = false
    }
    
    @IBAction func closeWindow() {
        if let presenter = self.presentingViewController{
            presenter.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Alerts
    
    func showAlert(title:String, message:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func presentBlueToothNotEnabled() {
        let blueToothAlert = UIAlertController(title: "Bluetooth is Disabled".localized, message: "We need to enable Bluetooth to connect the Hider and Seeker".localized, preferredStyle: .alert)
        let enableBluetoothAction = UIAlertAction(title: "Enable".localized, style: .default) { (_) in
            guard let url = URL(string: "App-Prefs:root=Bluetooth") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        blueToothAlert.addAction(enableBluetoothAction)
        self.present(blueToothAlert, animated: true, completion: nil)
    }

    
    func presentUserLost() {
        vibrate()
        self.statusLabel.textColor = UIColor.geraldine
        self.statusLabel.text = "The Seeker found you. You lost!".localized
        resetGame()
        checkBroadcastState()
    }
    
    
    // MARK: Helpers
    
    func vibrate() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func metersToFeet(distanceInMeters: Double) -> Double {
        return distanceInMeters * 3.28084
    }
    
    func disableHideButton() {
        hideButton.isEnabled = false
    }
    
    func enableHideButton() {
        hideButton.layer.borderColor = UIColor.myBlue.cgColor
        hideButton.setTitleColor(UIColor.myBlue, for: .normal)
        hideButton.isEnabled = true
        hideButton.isHidden = false
        
    }

    
    func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
    
    func resetStatusLabel() {
        self.statusLabel.text = ""
    }
    
    func resetGame() {
        isSearching = true
        toggleDiscovery()
        delayWithSeconds(2) {
            UIView.animate(withDuration: 2.0, animations: {
                self.statusLabel.alpha = 0.0
                self.statusLabel.textColor = UIColor.black
                self.resetStatusLabel()
            })
        }
    }
    
    // MARK: Locate Seekers Position
    
    func toggleDiscovery() {
        if !isSearching {
            self.initializeLocationManager(callback: { (success) in
                if success {
                    isSearching = true
                } else {
                    locationManager.requestAlwaysAuthorization()
                }
            })
        } else {
            if beaconRegion != nil {
                locationManager.stopMonitoring(for: beaconRegion)
                locationManager.stopRangingBeacons(in: beaconRegion)
                locationManager.stopUpdatingLocation()
                isSearching = false
            }
        }
    }
    
    func initializeLocationManager(callback:(Bool) -> Void) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            // Granted
            locationManager = CLLocationManager()
            locationManager.delegate = self
            
            guard let unwrappedUUID = self.uuid, let uuid = UUID(uuidString: unwrappedUUID) else {
                callback(false)
                return
            }
            beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "com.PatrickRidd.Timed-N-Seek-Seeker")
            beaconRegion.notifyOnEntry = true
            beaconRegion.notifyOnExit = true
            
            locationManager.startMonitoring(for: beaconRegion)
            locationManager.startUpdatingLocation()
            callback(true)
        } else {
            callback(false)
        }
    }
    
    func updateSatusLabels(beacons: [CLBeacon]) {
        statusLabel.isHidden = false
        guard let beacon = beacons.first else { return }
        
        let accuracy = String(format: "%.2f", self.metersToFeet(distanceInMeters: beacon.accuracy))
       
        if accuracy < "1.00" {
            self.presentUserLost()
            return
        } else {
            statusLabel.text = "Seeker is \(accuracy)ft away".localized
        }
        
        isSearching = false
        toggleDiscovery()
    }

    // MARK: CLLocationManagerDelegate functions
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            print("authorized...")
            break
        case .authorizedWhenInUse:
            break
        case .denied:
            break
        case .notDetermined:
            break
        case .restricted:
            break
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        locationManager.requestState(for: region)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            locationManager.startRangingBeacons(in: beaconRegion)
        case .outside:
            locationManager.stopRangingBeacons(in: beaconRegion)
        case .unknown:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            self.updateSatusLabels(beacons: beacons)
            locationManager.stopRangingBeacons(in: region)
        } else {
            resetStatusLabel()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Beacon region exited: \(region)")
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitring did fail: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print("failed: \(error)")
    }

}
