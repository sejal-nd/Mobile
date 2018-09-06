//
//  UINavigationController+Style.swift
//  BGE
//
//  Created by Joseph Erlandson on 9/5/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    func setWhiteNavBar() {
        navigationBar.barStyle = .default
        navigationBar.barTintColor = .white
        navigationBar.tintColor = .actionBlue
        navigationBar.isTranslucent = false
        
        // Re-add the bottom border line (in case it was removed on another screen)
        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.shadowImage = nil
        
        let titleDict: [NSAttributedStringKey: Any] = [
            .foregroundColor: UIColor.blackText,
            .font: OpenSans.bold.of(size: 18)
        ]
        navigationBar.titleTextAttributes = titleDict
        
        setNeedsStatusBarAppearanceUpdate()
        
        setNavigationBarHidden(false, animated: true)
    }
    
    func setColoredNavBar(hidesBottomBorder: Bool = false) {
        navigationBar.barStyle = .black
        navigationBar.barTintColor = .primaryColor
        navigationBar.tintColor = .white
        navigationBar.isTranslucent = false
        
        if hidesBottomBorder {
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
        } else {
            navigationBar.setBackgroundImage(nil, for: .default)
            navigationBar.shadowImage = nil
        }
        
        let titleDict: [NSAttributedStringKey: Any] = [
            .foregroundColor: UIColor.white,
            .font: OpenSans.bold.of(size: 18)
        ]
        navigationBar.titleTextAttributes = titleDict
        
        setNeedsStatusBarAppearanceUpdate()
        
        setNavigationBarHidden(false, animated: true)
    }
    
}