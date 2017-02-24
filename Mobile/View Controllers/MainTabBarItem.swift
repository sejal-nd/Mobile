//
//  MainTabBarItem.swift
//  Mobile
//
//  Created by Marc Shilling on 2/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MainTabBarItem: UITabBarItem {
    
    let normalTitleFont = UIFont.systemFont(ofSize: 10, weight: UIFontWeightRegular)
    let selectedTitleFont = UIFont.systemFont(ofSize: 10, weight: UIFontWeightBold)
    
    let normalTitleColor = UIColor.gray
    let selectedTitleColor = UIColor.primaryColor.darker()!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if self.tag == 1 {
            self.setTitleTextAttributes([NSFontAttributeName: selectedTitleFont, NSForegroundColorAttributeName: selectedTitleColor], for: UIControlState.normal)
        } else {
            self.setTitleTextAttributes([NSFontAttributeName: normalTitleFont, NSForegroundColorAttributeName: normalTitleColor], for: UIControlState.normal)
        }
    }
    
}
