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

    var seekerBeacon: CLBeaconRegion!
    var hiderBeacon: CLBeaconRegion!
    var locationManager: CLLocationManager!
    var peripheralManager: CBPeripheralManager!
    
    var uuid: String?
    let majorMinor = "123"
    let hiderLostMajorMinor = "666"
    let hiderWonMajorMinor = "777"
    
    var hiderWon = false
    var hiderLost = false
    
    var dataDictionary = [String: Any]()
    var distanceSetting: DistanceSetting = .feet
    
    @IBOutlet weak var hideButton:UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var hideThenTapLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBackButton()
        self.distanceSetting = SettingsController.sharedController.getDistanceSetting()
        setupOpeningLabel()
        
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
    
    
    
    ///////////////////////////////////////////////////////////////
    //                     MARK: UI Methods                      //
    ///////////////////////////////////////////////////////////////

    
    func setupOpeningLabel() {
        var measurement = ""
        
        switch distanceSetting {
        case .feet:
            measurement = "100 feet"
        case .meters:
            measurement = "30 meters"
        }
        
        self.hideThenTapLabel.text = "Hide within \(measurement), then tap...".localized
    }
    
    func loadingAnimation() {
        hideButton.alpha = 0.0
        hideThenTapLabel.alpha = 0.0
        UIView.animate(withDuration: 2.0) {
            self.hideThenTapLabel.alpha = 1.0
        }
        delayWithSeconds(2) {
            self.hideThenTapLabel.isHidden = true
            UIView.animate(withDuration: 1.5, animations: {
                self.hideButton.alpha = 1.0
            })
        }
    }
    
    func setBeaconStatusToHiding() {
        self.disableHideButton()
        self.hideButton.setTitle("Hiding".localized, for: .normal)
        self.hideButton.layer.borderColor = UIColor.burntOrange.cgColor
        self.hideButton.setTitleColor(UIColor.burntOrange, for: .normal)
    }
    
    func setBeaconStatusToHide() {
        self.enableHideButton()
        self.hideButton.setTitle("Hide".localized, for: .normal)
        self.hideButton.layer.borderColor = UIColor.myBlue.cgColor
        self.hideButton.setTitleColor(UIColor.myBlue, for: .normal)
    }
    
    func setButtonToLost() {
        self.hideButton.setTitle("Lost", for: .normal)
        self.hideButton.setTitleColor(.geraldine, for: .normal)
        self.hideButton.layer.borderColor = UIColor.geraldine.cgColor
    }
    
    func setButtonToWon() {
        self.hideButton.setTitle("Won".localized, for: .normal)
        self.hideButton.layer.borderColor = UIColor.goGreen.cgColor
        self.hideButton.setTitleColor(UIColor.goGreen, for: .normal)
    }
    
    func disableHideButton() {
        hideButton.isEnabled = false
    }
    
    func enableHideButton() {
        hideButton.isEnabled = true
        hideButton.isHidden = false
    }
    
    func setBackButton() {
        self.backButton.addTarget(self, action: #selector(backOrStopButtonTapped), for: .touchUpInside)
        self.backButton.setTitle("Back".localized, for: .normal)
    }
    
    func setStopButton() {
        self.backButton.setTitle("Stop".localized, for: .normal)
    }
    
    func setResetButton() {
        self.backButton.setTitle("Reset", for: .normal)
    }

    func resetStatusLabel() {
        self.statusLabel.text = ""
    }

    ///////////////////////////////////////////////////////////////
    //                  MARK: UI Alert Messages                  //
    ///////////////////////////////////////////////////////////////

  
    
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
    
    func presentNeedLocationPermission() {
        let alert = UIAlertController(title: "Need Location Permission", message: "You can give us permission in settings.", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(appSettings)
            }
        }
        alert.addAction(settingsAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentHiderLost() {
        
        // Set ring tone and vibrate for Hider Losing
        vibrate()
        
        self.hiderLost = true
       
        // Set Buttons to reflect that the Hider Lost
        setButtonToLost()
        setResetButton()
        
        // Blink Lost button
        
        
        self.statusLabel.text = "The Seeker found you. You lost!".localized
        
        // Broadcast appropriate beacon
        self.broadcastBeacon()
    }
    
    func presentHiderWon() {
       
        //set ring tone and vibrate for Hider Winning
        vibrate()
        
        self.hiderWon = true
        
        // Set Buttons to reflect that the Hider Won
        setResetButton()
        setButtonToWon()
        
        // Blink Lost button

        
        self.statusLabel.text = "You Won!! The seeker ran out of time".localized
        
        // If hider wins it means that the time ran out for seeker, so seeker already knows they lost.
        // So, stop searching and broadcasting.
        stopBroadCasting()
        stopSearchingForBeacon()
    }

    
    ///////////////////////////////////////////////////////////////
    //                  MARK: Gameplay methods                   //
    ///////////////////////////////////////////////////////////////
    
    
    func updateSatusLabels(beacons: [CLBeacon]) {
        statusLabel.isHidden = false
        guard let beacon = beacons.first else { return }
        
        DispatchQueue.main.async {
            self.displayDistanceFromSeeker(distance: beacon.accuracy)
        }
        hiderLost = determineIfHiderLost(seekerBeacon: beacon)
        hiderWon = determineIfHiderWon(seekerBeacon: beacon)
        
        if !hiderLost && !hiderWon {
            delayWithSeconds(0.5, completion: {
                self.discoverBeacons()
            })
        }
    }
    
    func resetGame() {
        stopSearchingForBeacon()
        hiderWon = false
        hiderLost = false
        stopBroadCasting()
        setBackButton()
        resetStatusLabel()
    }
    
    func displayDistanceFromSeeker(distance: CLLocationAccuracy) {
        var accuracy = ""
        if distanceSetting == .feet {
            accuracy = String(format: "%.2f", self.metersToFeet(distanceInMeters: distance))
            statusLabel.text = "Seeker is \(accuracy)ft away".localized
        } else {
            accuracy = String(format: "%.2f", distance)
            statusLabel.text = "Seeker is \(accuracy)m away".localized
        }
    }
    
    func determineIfHiderLost(seekerBeacon: CLBeacon) -> Bool {
        print(seekerBeacon.major)
        if seekerBeacon.major == 777 {
            print("777 Seeker Won, Hider Lost")
            presentHiderLost()
            return true
        }
        
        if distanceSetting == .feet {
            let accuracyInFeet = String(format: "%.2f", self.metersToFeet(distanceInMeters: seekerBeacon.accuracy))
            if accuracyInFeet < "3.00" {
                presentHiderLost()
                return true
            }
            
        } else {
            let accuracyInMeters = String(format: "%.2f", seekerBeacon.accuracy)
            if accuracyInMeters < "1.00" {
                presentHiderLost()
                return true
            }
        }
        return false
    }
    
    func determineIfHiderWon(seekerBeacon: CLBeacon) -> Bool {
        if seekerBeacon.major == 666 {
            print("666 Seeker ran out of time, Hider Won")
            presentHiderWon()
            return true
        }
        
        return false
    }

    
    ///////////////////////////////////////////////////////////////
    //                      MARK: Actions                        //
    ///////////////////////////////////////////////////////////////

    
    @IBAction func startButtonPressed(sender:Any){
        setStopButton()
        setBeaconStatusToHiding()
        resetStatusLabel()
        broadcastBeacon()
        discoverBeacons()
    }
    
    func backOrStopButtonTapped() {
        
        if backButton.titleLabel?.text == "Back".localized {
            closeWindow()
        } else {
            stopResetGameButtonPressed()
        }
    }
    
    func stopResetGameButtonPressed() {
        resetGame()
    }
    
    func closeWindow() {
        if let presenter = self.presentingViewController{
            presenter.dismiss(animated: true, completion: nil)
        }
    }
    
    
    ///////////////////////////////////////////////////////////////
    //                 MARK: Helper Methods                      //
    ///////////////////////////////////////////////////////////////

    
    func vibrate() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
       func metersToFeet(distanceInMeters: Double) -> Double {
        return distanceInMeters * 3.28084
    }
    
    func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }

    
    
    ///////////////////////////////////////////////////////////////
    //              MARK: Broadcasting methods                   //
    ///////////////////////////////////////////////////////////////
    
    
    func stopBroadCasting() {
        peripheralManager.stopAdvertising()
    }
    
    func broadcastBeacon() {
        // Attempt to broadcast
        switch peripheralManager.state {
        case .poweredOn:
            self.determineBeaconToCreate()
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
    }
    
    
    func determineBeaconToCreate() {
        peripheralManager.stopAdvertising()
        if hiderLost {
            // create hiderLost beacon
            hiderBeacon = self.createHiderLostBeacon()
        } else if hiderWon {
            // create hiderWonBeacon
            hiderBeacon = self.createHiderWonBeacon()
        } else {
            // Hider is Hiding
            hiderBeacon = self.createBeaconRegion()
        }
        
        advertiseHiderBeacon()
    }
    
    func createBeaconRegion() -> CLBeaconRegion? {
        guard let uuidString = self.uuid, let uuid = UUID(uuidString: uuidString), let major = Int(self.majorMinor), let minor = Int(self.majorMinor)
            else { return nil }
        return CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(major), minor: CLBeaconMinorValue(minor), identifier: "com.PatrickRidd.Timed-N-Seek-Hider")
        
    }
    
    func createHiderWonBeacon() -> CLBeaconRegion? {
        guard let uuidString = self.uuid, let uuid = UUID(uuidString: uuidString), let major = Int(self.hiderWonMajorMinor), let minor = Int(self.hiderWonMajorMinor)
            else { return nil }
        return CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(major), minor: CLBeaconMinorValue(minor), identifier: "com.PatrickRidd.Timed-N-Seek-Hider")
        
    }
    
    func createHiderLostBeacon() -> CLBeaconRegion? {
        guard let uuidString = self.uuid, let uuid = UUID(uuidString: uuidString), let major = Int(self.hiderLostMajorMinor), let minor = Int(self.hiderLostMajorMinor)
            else { return nil }
        return CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(major), minor: CLBeaconMinorValue(minor), identifier: "com.PatrickRidd.Timed-N-Seek-Hider")
        
    }

    func advertiseHiderBeacon() {
        guard hiderBeacon != nil else { return }
        guard let dataDictionary = hiderBeacon.peripheralData(withMeasuredPower: nil) as? [String: Any] else {
            showAlert(title: "Error Connecting".localized, message: "We are having trouble signaling the device. Please try again.".localized)
            return
        }
        peripheralManager.startAdvertising(dataDictionary)
        
    }
    
    
    ///////////////////////////////////////////////////////////////
    //          MARK: CBPeripheralManagerDelegate                //
    ///////////////////////////////////////////////////////////////
    
    
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
    
    
    ///////////////////////////////////////////////////////////////
    //              MARK: Search Beacon Methods                  //
    ///////////////////////////////////////////////////////////////
    
    func discoverBeacons() {
            self.initializeLocationManager(callback: { (success) in
                if !success {
                    self.presentNeedLocationPermission()
                }
            })
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
            seekerBeacon = CLBeaconRegion(proximityUUID: uuid, identifier: "com.PatrickRidd.Timed-N-Seek-Seeker")
            seekerBeacon.notifyOnEntry = true
            seekerBeacon.notifyOnExit = true
            
            locationManager.startMonitoring(for: seekerBeacon)
            locationManager.startUpdatingLocation()
            callback(true)
        } else {
            callback(false)
        }
    }
    
    func stopSearchingForBeacon() {
        locationManager.stopMonitoring(for: seekerBeacon)
        locationManager.stopRangingBeacons(in: seekerBeacon)
        locationManager.stopUpdatingLocation()
    }
    
    
    ///////////////////////////////////////////////////////////////
    //      MARK: CLLocationManagerDelegate functions            //
    ///////////////////////////////////////////////////////////////
    
    
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
            locationManager.startRangingBeacons(in: seekerBeacon)
        case .outside:
            locationManager.stopRangingBeacons(in: seekerBeacon)
        case .unknown:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            self.updateSatusLabels(beacons: beacons)
            locationManager.stopRangingBeacons(in: region)
        } else {
            delayWithSeconds(3, completion: {
                self.statusLabel.text = "Trying to locate Seeker's distance...".localized
            })
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
