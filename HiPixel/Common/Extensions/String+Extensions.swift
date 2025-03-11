//
//  String+Extensions.swift
//  HiPixel
//
//  Created by 十里 on 2025/3/11.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
