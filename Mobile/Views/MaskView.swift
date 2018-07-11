//
//  MaskView.swift
//  Mobile
//
//  Created by Joseph Erlandson on 6/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class MaskView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners([.topLeft, .topRight], radius: 10.0)
    }
    
}
