//
//  FinaledView.swift
//  EUMobile
//
//  Created by RAMAITHANI on 11/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class FinaledView: UIView {

    @IBOutlet weak var serviceStatusLabel: UILabel!
    @IBOutlet weak var helplineDescriptionLabel: UILabel!
    
    override func awakeFromNib() {
        
        fontStyle()
    }
    
    private func fontStyle() {
        
        helplineDescriptionLabel.font = SystemFont.semibold.of(textStyle: .title3)
        helplineDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
    }
}
