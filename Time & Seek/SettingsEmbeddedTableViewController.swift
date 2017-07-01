//
//  SettingsEmbeddedTableViewController.swift
//  Time & Seek
//
//  Created by Patrick Ridd on 6/23/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit

class SettingsEmbeddedTableViewController: UITableViewController {
    
    let distanceKey = "distanceKey"
    let timeKey = "timeKey"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSettings()
    }
    
    func setupSettings() {
        let distanceSettings = SettingsController.sharedController.getDistanceSetting()
        let timeSettings = SettingsController.sharedController.getTimeSetting()
        
        
        switch timeSettings {
        case .twentySeconds: highlightSaveTimeSection(row: 0)
        case.fortySeconds: highlightSaveTimeSection(row: 1)
        case .sixtySeconds: highlightSaveTimeSection(row: 2)
        }
        
        switch distanceSettings {
        case .feet: highlightSaveDistanceSection(row: 0)
        case .meters: highlightSaveDistanceSection(row: 1)
        }
    }
    
    func highlightSaveTimeSection(row: Int) {
        let indexPath = IndexPath(row: row, section: 0)
        let cell = tableView.cellForRow(at: indexPath)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.myBlue
        cell?.selectedBackgroundView = backgroundView
        
        switch row {
        case 0: SettingsController.sharedController.setTimeSetting(timeSetting: .twentySeconds)
        case 1: SettingsController.sharedController.setTimeSetting(timeSetting: .fortySeconds)
        case 2: SettingsController.sharedController.setTimeSetting(timeSetting: .sixtySeconds)
        default: break
        }
        
    }
    
    func highlightSaveDistanceSection(row: Int) {
        let indexPath = IndexPath(row: row, section: 1)
        let cell = tableView.cellForRow(at: indexPath)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.myBlue
        cell?.selectedBackgroundView = backgroundView
        
        switch row {
        case 0: SettingsController.sharedController.setDistanceSetting(distanceSetting: .feet)
        case 1: SettingsController.sharedController.setDistanceSetting(distanceSetting: .meters)
        default: break
        }
    }

    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            highlightSaveTimeSection(row: indexPath.row)
        } else {
            highlightSaveDistanceSection(row: indexPath.row)
        }
    }
    
}
