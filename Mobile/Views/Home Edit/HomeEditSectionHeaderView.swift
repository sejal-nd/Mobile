//
//  HomeEditSectionHeaderView.swift
//  Mobile
//
//  Created by Samuel Francis on 6/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class HomeEditSectionHeaderView: UICollectionReusableView {
    
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        label.font = OpenSans.semibold.of(textStyle: .title1)
    }
    
}
