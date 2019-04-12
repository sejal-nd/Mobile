//
//  UITextViewFixed.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/15/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class ZeroInsetDataDetectorTextView: DataDetectorTextView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    private func commonInit() {
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
    }
    
}
