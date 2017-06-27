//
//  SettingsController.swift
//  Time & Seek
//
//  Created by Patrick Ridd on 6/26/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import Foundation

class SettingsController {
    
    static let sharedController = SettingsController()
    let distanceKey = "distanceKey"
    let timeKey = "timeKey"

    
    func getTimeSetting() -> TimeSetting {
        let timeSetting = UserDefaults().object(forKey: timeKey) as? String
        
        guard let time = timeSetting, let timeCase = TimeSetting(rawValue: time) else { return .twentySeconds }
        
        return timeCase
    }
    
    func getDistanceSetting() -> DistanceSetting {
        let distanceSetting = UserDefaults().object(forKey: self.distanceKey) as? String
        
        guard let distance = distanceSetting, let distanceCase = DistanceSetting(rawValue: distance) else { return .feet }
        
        return distanceCase
    }

    func setTimeSetting(timeSetting: TimeSetting) {
        UserDefaults().set(timeSetting.rawValue, forKey: self.timeKey)
    }
    
    func setDistanceSetting(distanceSetting: DistanceSetting) {
        UserDefaults().set(distanceSetting.rawValue, forKey: self.distanceKey)
    }
    
    
    
}
