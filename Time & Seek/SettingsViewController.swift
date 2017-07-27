//
//  SettingsViewController.swift
//  Time & Seek
//
//  Created by Patrick Ridd on 6/23/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var closeButton: LocalizedButton!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        self.closeButton.setTitleColor(.geraldine, for: .normal)
    }
    
    func didTapCloseButton() {
        SoundsController.sharedController.play(sound: .closeWindow)
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
