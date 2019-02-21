//
//  UITableView+ResizableHeaderFooter.swift
//  BGE
//
//  Created by Joseph Erlandson on 2/21/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

extension UITableView {
    func sizeHeaderToFit() {
        if let headerView = tableHeaderView {
            headerView.setNeedsLayout()
            headerView.layoutIfNeeded()
            
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var frame = headerView.frame
            frame.size.height = height
            headerView.frame = frame
            
            tableHeaderView = headerView
        }
    }
    
    func sizeFooterToFit() {
        if let footerView = tableFooterView {
            footerView.setNeedsLayout()
            footerView.layoutIfNeeded()
            
            let height = footerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var frame = footerView.frame
            frame.size.height = height
            footerView.frame = frame
            
            tableFooterView = footerView
        }
    }
}
