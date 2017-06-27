//
//  LocalizedButton.swift
//  Time & Seek
//
//  Created by Patrick Ridd on 6/23/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit

class LocalizedButton: UIButton {

    override func awakeFromNib() {
        self.setTitle(self.titleLabel?.text?.localized, for: .normal)
    }
}
