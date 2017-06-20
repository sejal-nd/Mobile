//
//  IntrinsicHeightTableView.swift
//  Mobile
//
//  Created by Marc Shilling on 6/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

class IntrinsicHeightTableView: UITableView {
    
    override var contentSize:CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIViewNoIntrinsicMetric, height: contentSize.height)
    }
    
}
