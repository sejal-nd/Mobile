//
//  MainTabBarController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    let normalTitleFont = SystemFont.regular.of(textStyle: .caption2)
    let selectedTitleFont = SystemFont.bold.of(textStyle: .caption2)
    
    let normalTitleColor = UIColor.middleGray
    let selectedTitleColor = UIColor.primaryColorADA
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.InMainApp)
        
        tabBar.barTintColor = .white
        tabBar.tintColor = .primaryColor
        tabBar.isTranslucent = false
        
        setButtonStates(itemTag: 1)
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        setButtonStates(itemTag: item.tag)
    }
    
    // Needed for programmatically changing tabs
    override var selectedIndex: Int {
        didSet {
            setButtonStates(itemTag: selectedIndex + 1)
        }
    }
    
    func setButtonStates (itemTag: Int) {
        for tab in tabBar.items! {
            if tab.tag == itemTag {
                tab.setTitleTextAttributes([NSFontAttributeName: selectedTitleFont, NSForegroundColorAttributeName: selectedTitleColor], for: .normal)
            } else {
                tab.setTitleTextAttributes([NSFontAttributeName: normalTitleFont, NSForegroundColorAttributeName: normalTitleColor], for: .normal)
            }
        }
    }
    
}
