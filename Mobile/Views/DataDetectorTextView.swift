//
//  DataDetectorTextView.swift
//  Mobile
//
//  Created by Marc Shilling on 3/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class DataDetectorTextView: UITextView {
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        isEditable = false
        dataDetectorTypes = .phoneNumber
        accessibilityTraits = UIAccessibilityTraitStaticText
    }

}
