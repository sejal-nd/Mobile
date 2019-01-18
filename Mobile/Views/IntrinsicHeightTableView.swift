//
//  IntrinsicHeightTableView.swift
//  Mobile
//
//  Created by Marc Shilling on 6/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class IntrinsicHeightTableView: UITableView {
    
    override var contentSize:CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
    
}
