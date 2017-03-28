//
//  MainTabBarController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    let normalTitleFont = UIFont.systemFont(ofSize: 10)
    let selectedTitleFont = UIFont.boldSystemFont(ofSize: 10)
    
    let normalTitleColor = UIColor.gray
    let selectedTitleColor = UIColor.primaryColorDark
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
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
        let tabs = self.tabBar.items
        
        var x = 0
        while x < (tabs?.count)! {
            if tabs?[x].tag == itemTag {
                tabs?[x].setTitleTextAttributes([NSFontAttributeName: selectedTitleFont, NSForegroundColorAttributeName: selectedTitleColor], for: UIControlState.normal)
            } else {
                tabs?[x].setTitleTextAttributes([NSFontAttributeName: normalTitleFont, NSForegroundColorAttributeName: normalTitleColor], for: UIControlState.normal)
            }
            x += 1
        }
    }
    
}
