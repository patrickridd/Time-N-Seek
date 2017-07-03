//
//  SettingsEmbeddedTableViewController.swift
//  Time & Seek
//
//  Created by Patrick Ridd on 6/23/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit

class SettingsEmbeddedTableViewController: UITableViewController {
    
    @IBOutlet weak var twentyCheckMark: UIImageView!
    
    @IBOutlet weak var fortyCheckMark: UIImageView!
    
    @IBOutlet weak var sixtyCheckMark: UIImageView!
    
    @IBOutlet weak var feetCheckMark: UIImageView!
    
    @IBOutlet weak var metersCheckMark: UIImageView!
    
    let distanceKey = "distanceKey"
    let timeKey = "timeKey"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.reloadData()
        setupSettings()
    }
    
    func setupSettings() {
        let distanceSettings = SettingsController.sharedController.getDistanceSetting()
        let timeSettings = SettingsController.sharedController.getTimeSetting()
        
        
        switch timeSettings {
        case .twentySeconds: hideCheckMarks(inSection: 0, exceptRow: 0)
        case.fortySeconds: hideCheckMarks(inSection: 0, exceptRow: 1)
        case .sixtySeconds: hideCheckMarks(inSection: 0, exceptRow: 2)
        }
        
        switch distanceSettings {
        case .feet: hideCheckMarks(inSection: 1, exceptRow: 0)
        case .meters: hideCheckMarks(inSection: 1, exceptRow: 1)
        }
    }
    
    func saveSetting(inSection section: Int, forRow row: Int) {
        if section == 0 {
            switch row {
            case 0: SettingsController.sharedController.setTimeSetting(timeSetting: .twentySeconds)
            case 1: SettingsController.sharedController.setTimeSetting(timeSetting: .fortySeconds)
            case 2: SettingsController.sharedController.setTimeSetting(timeSetting: .sixtySeconds)
            default: break
            }
            
        } else {
            switch row {
            case 0: SettingsController.sharedController.setDistanceSetting(distanceSetting: .feet)
            case 1: SettingsController.sharedController.setDistanceSetting(distanceSetting: .meters)
            default: break
            }
        }
    }
        
    
    func hideCheckMarks(inSection section: Int, exceptRow row: Int) {
        
        if section == 0 {
            // Hide all checkmarks in section 0 except for the specific row case
            switch row {
            case 0:
                self.twentyCheckMark.isHidden = false // reveals the case row checkmark
                self.fortyCheckMark.isHidden = true
                self.sixtyCheckMark.isHidden = true
            case 1:
                self.fortyCheckMark.isHidden = false // reveals the case row checkmark
                self.twentyCheckMark.isHidden = true
                self.sixtyCheckMark.isHidden = true
            default:
                self.sixtyCheckMark.isHidden = false // reveals the case row checkmark
                self.twentyCheckMark.isHidden = true
                self.fortyCheckMark.isHidden = true
                
                
            }
        } else if section == 1 {
            // Hide all checkmarks in section 1 except for the specific row case
                switch row {
                case 0:
                    self.feetCheckMark.isHidden = false  // reveals the case row checkmark
                    self.metersCheckMark.isHidden = true
                default:
                    self.metersCheckMark.isHidden = false  // reveals the case row checkmark
                    self.feetCheckMark.isHidden = true
                }
            }
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            saveSetting(inSection: indexPath.section, forRow: indexPath.row)
            setupSettings()
    }
    
}
