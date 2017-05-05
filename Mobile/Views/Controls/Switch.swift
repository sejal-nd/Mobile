//
//  Switch.swift
//  Mobile
//
//  Created by Marc Shilling on 2/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class Switch: UISwitch {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        style()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        style()
    }
    
    func style() {
        tintColor = UIColor(red: 193/255, green: 193/255, blue: 193/255, alpha: 1) // Border color around the "off" state
        backgroundColor = .accentGray
        onTintColor = .primaryColor
        layer.cornerRadius = 16
    }
    
}
