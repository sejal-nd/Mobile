//
//  NSAttributedString+ColorInRange.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension String {
    public func textWithColorAndFontInRange(color: UIColor, font: UIFont) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(string: self)
        attributedText.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: 1))
        attributedText.addAttribute(.font, value: font, range: NSRange(location: 0, length: self.count))
        return attributedText
    }
}
