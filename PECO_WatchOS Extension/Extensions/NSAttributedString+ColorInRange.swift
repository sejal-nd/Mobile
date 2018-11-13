//
//  NSAttributedString+ColorInRange.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension String {
    
    public func textWithColorInRange(color: UIColor, range: NSRange, shouldChangeFontSize: Bool = false) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(string: self)
        attributedText.addAttribute(.foregroundColor, value: color, range: range)
        
        if shouldChangeFontSize {
            
            //attributedText.addAttribute(.font, value: <#T##Any#>, range: range)
        }
        
        return attributedText
    }
    
}
