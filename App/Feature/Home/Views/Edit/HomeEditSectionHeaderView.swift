//
//  HomeEditSectionHeaderView.swift
//  Mobile
//
//  Created by Samuel Francis on 6/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class HomeEditSectionHeaderView: UICollectionReusableView {
    
    static let instructionsLabelString = NSLocalizedString("Personalize your home screen to include features you would like. You can rearrange cards in use at any time.", comment: "")
    
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        instructionsLabel.textColor = .neutralDark
        instructionsLabel.font = .headline
        instructionsLabel.text = HomeEditSectionHeaderView.instructionsLabelString
        
        label.textColor = .neutralDark
        label.font = .headline
    }
    
}
