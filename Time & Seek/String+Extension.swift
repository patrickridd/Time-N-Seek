//
//  String+Extension.swift
//  Time & Seek
//
//  Created by Patrick Ridd on 6/21/17.
//  Copyright © 2017 PatrickRidd. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
