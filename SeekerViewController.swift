//
//  SeekerViewController.swift
//  Timed N Seek
//
//  Created by Patrick Ridd on 5/31/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth
import AudioToolbox

class SeekerViewController: UIViewController, CLLocationManagerDelegate, CBPeripheralManagerDelegate {

    @IBOutlet weak var statusLabel:UILabel!
    @IBOutlet weak var seekButton:UIButton!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var letHiderHideLabel: UILabel!
    
    var uuid: String?
    var hiderBeacon: CLBeaconRegion!
    var seekerBeacon: CLBeaconRegion!
    var locationManager: CLLocationManager!
    var peripheralManager: CBPeripheralManager!
    var isBroadcasting: Bool = false
    let seekerMinor = "456"
    let seekerMajor = "456"
    
    private var timer: Timer?
    private var timeSetting: TimeSetting = .twentySeconds
    private var distanceSetting: DistanceSetting = .feet
    private var elapsedTimeInSecond: Int = 20
    private var startTime: Int = 20
    
    var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get game settings
        timeSetting = SettingsController.sharedController.getTimeSetting()
        distanceSetting = SettingsController.sharedController.getDistanceSetting()
        
        reloadSeconds()
        seekButton.layer.borderWidth = 1.0
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        peripheralManager = CBPeripheralManager(delegate: self as CBPeripheralManagerDelegate, queue: nil, options: nil)
        backButton.addTarget(self, action: #selector(backOrStopButtonTapped), for: .touchUpInside)
        backButton.setTitleColor(UIColor.geraldine, for: .normal)
        loadingAnimation()
        
    }
    
    func loadingAnimation() {
        seekButton.alpha = 0.0
        letHiderHideLabel.alpha = 0.0
        UIView.animate(withDuration: 2.0) {
            self.letHiderHideLabel.alpha = 1.0
        }
        delayWithSeconds(2) {
            self.letHiderHideLabel.isHidden = true
            UIView.animate(withDuration: 1.5, animations: {
                self.seekButton.alpha = 1.0
                self.setSeekButtonToNormal()
            })
        }
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
            locationManager.startRangingBeacons(in: hiderBeacon)
        case .outside:
            locationManager.stopRangingBeacons(in: hiderBeacon)
        case .unknown:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            self.updateSatusLabels(beacons: beacons)
            locationManager.stopRangingBeacons(in: region)
        } else {
           // self.presentCantFindBeacon()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Beacon region exited: \(region)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //self.presentCantFindBeacon()
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
       // self.presentCantFindBeacon()
        print("Monitring did fail: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print("failed: \(error)")
    }
    
    // MARK: Main
    
    
    func initializeLocationManager(callback:(Bool) -> Void) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            // Granted
            locationManager = CLLocationManager()
            locationManager.delegate = self
            
            guard let unwrappedUUID = self.uuid, let uuid = UUID(uuidString: unwrappedUUID) else {
                callback(false)
                self.presentScanQRCode()
                return
            }
            hiderBeacon = CLBeaconRegion(proximityUUID: uuid, identifier: "com.PatrickRidd.Timed-N-Seek-Hider")
            hiderBeacon.notifyOnEntry = true
            hiderBeacon.notifyOnExit = true
            
            locationManager.startMonitoring(for: hiderBeacon)
            locationManager.startUpdatingLocation()
            callback(true)
        } else {
            self.presentNeedLocationPermission()
            callback(false)
        }
    }
    
    func toggleDiscovery() {
        if !isSearching {
            self.initializeLocationManager(callback: { (success) in
                if success {
                    isSearching = true
                } else {
                    resetGame()
                }
            })
        } else {
            stopLocatingHider()
            resetTimer()
            isSearching = false
            updateButtonTitle()
        }
    }
    
    func updateSatusLabels(beacons: [CLBeacon]) {
        statusLabel.isHidden = false
        guard let beacon = beacons.first else { self.presentCantFindBeacon(); return }
        if elapsedTimeInSecond == self.startTime {
            startTimer()
        }

        displayDistance(for: beacon)
        determineIfSeekerWon(distance: beacon.accuracy)
        delayWithSeconds(0.5) {
            self.toggleDiscovery()
        }
        
    }
    
    func resetGame() {
        isSearching = true
        stopLocatingHider()
        resetTimer()
        instructionsLabel.isHidden = true
        backButton.setTitle("Back".localized, for: .normal)
        enableSeekButton()
        toggleDiscovery()
        delayWithSeconds(2) {
            UIView.animate(withDuration: 2.0, animations: {
                self.statusLabel.alpha = 0.0
                self.statusLabel.text = ""
                self.statusLabel.textColor = UIColor.black

            })
        }

    }
    
    func setSeekButtonToNormal() {
        self.seekButton.setTitle("Seek".localized, for: .normal)
        self.seekButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        self.seekButton.layer.borderColor = UIColor.myBlue.cgColor
        self.seekButton.setTitleColor(UIColor.myBlue, for: .normal)
    }
    
    func startTimer() {
        self.updateTimeLabel()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            self.elapsedTimeInSecond -= 1
            self.updateTimeLabel()
            if self.elapsedTimeInSecond == 0 {
                self.presentUserLost()
            }
        })
        
    }
    
    // MARK: User Alert Messages
    
    func presentCantFindBeacon() {
        statusLabel.text = ""
        resetGame()
        var distance: String = "100 feet"
        if distanceSetting == .meters { distance = "30 meters" }
        
        let alert = UIAlertController(title: "Can't find Hider's Beacon".localized, message: "Ensure they tap \"Hide\" and are within \(distance)".localized, preferredStyle: .alert)
        let gotItAction = UIAlertAction(title: "Got it".localized, style: .default, handler: nil)
        alert.addAction(gotItAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentUserWon() {
        vibrate()
        self.statusLabel.textColor = UIColor.green
        statusLabel.text = "You found the Hider!! You won!".localized
        checkBroadcastState()
        resetGame()
    }
    
    func presentUserLost() {
        vibrate()
        self.statusLabel.textColor = UIColor.geraldine
        self.statusLabel.text = "You Lost!!!".localized
        checkBroadcastState()
        resetGame()
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
    
    func presentScanQRCode() {
        let alert = UIAlertController(title: "Re-Scan QR Code".localized, message: "We don't have Hider's QR Code info.".localized, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay".localized, style: .default) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
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
    
    func showAlert(title:String, message:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay".localized, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    // MARK: Timer methods
    
    func reloadSeconds() {
        switch self.timeSetting {
        case .twentySeconds:
            self.elapsedTimeInSecond = 20
        case .fortySeconds:
            self.elapsedTimeInSecond = 40
        case .sixtySeconds:
            self.elapsedTimeInSecond = 60
        }
        
        self.startTime = elapsedTimeInSecond
    }
    
    func pauseTimer() {
        timer?.invalidate()
    }
    
    func resetTimer() {
        timer?.invalidate()
        reloadSeconds()
    }
    
    func updateTimeLabel() {
        let seconds = elapsedTimeInSecond % 60
        self.seekButton.titleLabel?.font = UIFont.systemFont(ofSize: 28)
        self.seekButton.setTitle(String(format: "%2d", elapsedTimeInSecond), for: .normal)
    }

    
    func updateButtonTitle() {
        if isSearching {
            self.seekButton.layer.borderColor = UIColor.green.cgColor
            self.seekButton.setTitleColor(UIColor.green, for: .normal)
        } else {
            setSeekButtonToNormal()
        }
    }
    
    func startGame() {
        disableSeekButton()
        instructionsLabel.text = ""
        self.instructionsLabel.text = ""
        var untilGameStarts = 4
        self.statusLabel.isHidden = false
        self.statusLabel.alpha = 1.0
        self.backButton.isHidden = true
        var readyOrNot = ["Here I come".localized,"Not".localized,"Or".localized,"Ready".localized]
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true, block: { (timer) in
            untilGameStarts -= 1
            self.seekButton.setTitle("\(untilGameStarts)", for: .normal)
            self.statusLabel.text = readyOrNot[untilGameStarts]
            
            if untilGameStarts == 0 {
                var distance = "3 feet"
                if self.distanceSetting == .meters { distance = "1 meter" }
                self.instructionsLabel.text = "Get within \(distance) of Hider".localized
                self.pauseTimer()
                self.backButton.setTitle("Stop".localized, for: .normal)
                self.backButton.isHidden = false
                self.seekButton.layer.borderColor = UIColor.goGreen.cgColor
                self.seekButton.setTitleColor(UIColor.goGreen, for: .normal)
                self.seekButton.setTitle("Seeking".localized, for: .normal)
                self.delayWithSeconds(2, completion: {
                    self.instructionsLabel.text = ""
                    self.checkBroadcastState()
                    self.toggleDiscovery()

                })
            }
        })

    }
   
    // MARK: Actions
    @IBAction func startButtonPressed(sender:Any){
        resetTimer()
        if !isSearching {
            startGame()
        } else {
            self.toggleDiscovery()
        }
    }
    
    func backOrStopButtonTapped() {
        
        if backButton.titleLabel?.text == "Back".localized {
            if let presenter = self.presentingViewController{
                presenter.dismiss(animated: true, completion: nil)
            }
        } else {
            resetGame()
            statusLabel.text = ""
        }
    }
    
    // MARK: Helpers
    func getProximityString(proximity: CLProximity) -> String {
        switch proximity {
        case .immediate:
            return "Immediate".localized
        case .far:
            return "Far".localized
        case .near:
            return "Near".localized
        case .unknown:
            return "Unknown".localized
        }
    }
    
    func stopLocatingHider() {
        if hiderBeacon != nil {
            locationManager.stopMonitoring(for: hiderBeacon)
            locationManager.stopRangingBeacons(in: hiderBeacon)
            locationManager.stopUpdatingLocation()
        }
    }
    
    func determineIfSeekerWon(distance: CLLocationAccuracy) {
        if distanceSetting == .feet {
            let accuracyInFeet = String(format: "%.2f", self.metersToFeet(distanceInMeters: distance))
            if accuracyInFeet < "3.00" {
                presentUserWon()
            }
        } else {
            let accuracyInMeters = String(format: "%.2f", distance)
            if accuracyInMeters < "1.00" {
                presentUserWon()
            }
        }
    }
    
    func displayDistance(for beacon: CLBeacon) {
        if distanceSetting == .feet {
            let accuracyInFeet = String(format: "%.2f", self.metersToFeet(distanceInMeters: beacon.accuracy))
            statusLabel.text = "Hider is \(accuracyInFeet)ft away".localized
        } else {
            let accuracyInMeters = String(format: "%.2f",beacon.accuracy)
            statusLabel.text = "Hider is \(accuracyInMeters)m away".localized
        }
    }
    
    func metersToFeet(distanceInMeters: Double) -> Double {
        return distanceInMeters * 3.28084
    }
    
    func vibrate() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }

    func disableSeekButton() {
        seekButton.isEnabled = false
    }
    
    func enableSeekButton() {
        seekButton.layer.borderColor = UIColor.myBlue.cgColor
        seekButton.setTitleColor(UIColor.myBlue, for: .normal)
        seekButton.isEnabled = true
        seekButton.isHidden = false

    }
    
    /**
     Fade in a view with a duration
     
     - parameter duration: custom animation duration
     */
    func fadeIn(withDuration duration: TimeInterval = 1.0, view: UIView) {
        UIView.animate(withDuration: duration, animations: {
            view.alpha = 1.0
        })
    }
    
    /**
     Fade out a view with a duration
     
     - parameter duration: custom animation duration
     */
    func fadeOut(withDuration duration: TimeInterval = 1.0, view: UIView) {
        UIView.animate(withDuration: duration, animations: {
            view.alpha = 0.0
        })
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn: break
        case .poweredOff:
            self.presentBlueToothNotEnabled()
        case .resetting: break
        case .unauthorized: break
        case .unsupported: break
        case .unknown: break
        
        }
    }
    
    
    // MARK: Broadcast Beacon
    
    func checkBroadcastState() {
        if !isBroadcasting {
            // Attempt to broadcast
            switch peripheralManager.state {
            case .poweredOn:
                self.startAdvertising()
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
        }
    }
    
    func createBeaconRegion() -> CLBeaconRegion? {
        guard let uuidString = self.uuid, let uuid = UUID(uuidString: uuidString), let major = CLBeaconMajorValue(self.seekerMajor), let minor = CLBeaconMinorValue(self.seekerMinor) else {
            return nil
        }
        return CLBeaconRegion(proximityUUID: uuid, major: major, minor: minor, identifier: "com.PatrickRidd.Timed-N-Seek-Seeker")
        
    }
    
    func startAdvertising() {
        seekerBeacon = self.createBeaconRegion()
        guard seekerBeacon != nil else { return }
        guard let dataDictionary = seekerBeacon.peripheralData(withMeasuredPower: nil) as? [String: Any] else {
            showAlert(title: "Error Connecting".localized, message: "We are having trouble signaling the device. Please try again.".localized)
            isBroadcasting = false
            return
        }
        
        peripheralManager.startAdvertising(dataDictionary)
        isBroadcasting = true
    }


}
