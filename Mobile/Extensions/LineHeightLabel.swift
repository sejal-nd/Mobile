//
//  LineHeightLabel.swift
//  Mobile
//
//  Created by Marc Shilling on 3/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UILabel {
    
    func setLineHeight(lineHeight: CGFloat) {
        if let text = self.text {
            let attributeString = NSMutableAttributedString(string: text)
            let style = NSMutableParagraphStyle()
            
            style.minimumLineHeight = lineHeight
            attributeString.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, text.count))
            self.attributedText = attributeString
        }
    }
    
}

extension String {
    
    func attributedString(withLineHeight lineHeight: CGFloat, textAlignment: NSTextAlignment = .left) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.alignment = textAlignment
        
        let attributedString = NSMutableAttributedString(string: self)
        attributedString.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, count))
        return attributedString
    }
    
}
