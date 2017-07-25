//
//  SoundsController.swift
//  Time & Seek
//
//  Created by Patrick Ridd on 7/25/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import Foundation
import AVFoundation

class SoundsController {
    
    static let sharedController = SoundsController()
    
    var player: AVAudioPlayer?
    
    func play(sound: Sound) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
            print("error")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
