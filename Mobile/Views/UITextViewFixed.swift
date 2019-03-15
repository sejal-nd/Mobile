//
//  UITextViewFixed.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/15/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

@IBDesignable class UITextViewFixed: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    func setup() {
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
    }
}
