//
//  UITextViewFixed.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/15/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

@IBDesignable class ZeroInsetDataDetectorTextView: DataDetectorTextView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    
    private func setup() {
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
    }
    
}
