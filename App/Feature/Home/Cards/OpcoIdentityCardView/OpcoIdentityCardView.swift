//
//  OpcoIdentityCardView.swift
//  BGE
//
//  Created by Majumdar, Amit on 22/07/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit

class OpcoIdentityCardView: UIView {
        
    @IBOutlet weak var accountNickname: UILabel!
        
    static func create(withViewModel viewModel: OpcoIdentityViewModel) -> OpcoIdentityCardView {
        let view = Bundle.main.loadViewFromNib() as OpcoIdentityCardView
        view.styleViews()
        return view
    }
    
    func styleViews() {
        backgroundColor = .primaryColor
        accountNickname.textColor = .white
        accountNickname.isAccessibilityElement = true
        accessibilityElements = [accountNickname] as [UIView]
    }
    
    func configure(nickname: String, opco: OpCo) {
        accountNickname.text = nickname
    }
}
