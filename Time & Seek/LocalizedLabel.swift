//
//  LocalizedLabel.swift
//  Time & Seek
//
//  Created by Patrick Ridd on 6/21/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import UIKit

class LocalizedLabel: UILabel {
    
    override func awakeFromNib() {
        self.text = self.text?.localized
    }

}
