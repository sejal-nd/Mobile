//
//  MainTabBarController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    let normalTitleFont = UIFont.systemFont(ofSize: 10, weight: UIFontWeightRegular)
    let selectedTitleFont = UIFont.systemFont(ofSize: 10, weight: UIFontWeightBold)
    
    let normalTitleColor = UIColor.gray
    let selectedTitleColor = UIColor.primaryColor.darker()!
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        setButtonStates(itemTag: item.tag)
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
