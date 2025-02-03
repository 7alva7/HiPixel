//
//  Ext+String.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/31.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}