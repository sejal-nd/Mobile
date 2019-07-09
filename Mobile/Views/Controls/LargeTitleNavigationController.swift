//
//  LargeTitleNavigationController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/9/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class LargeTitleNavigationController: UINavigationController {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        commonInit()
    }
    
    
    private func commonInit() {
        navigationBar.barStyle = .default
        navigationBar.barTintColor = StormModeStatus.shared.isOn ? .stormModeBlack : .white
        navigationBar.tintColor = .actionBlue
        navigationBar.isTranslucent = false
        
        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.shadowImage = UIColor.primaryColor.image()
        
        if #available(iOS 11.0, *) {
            navigationBar.largeTitleTextAttributes = [
                .foregroundColor: StormModeStatus.shared.isOn ? UIColor.white : UIColor.blackText,
                .font: OpenSans.bold.of(size: 20)
            ]
            navigationItem.largeTitleDisplayMode = .always
            navigationBar.prefersLargeTitles = true
        }
        
        navigationBar.titleTextAttributes = [
            .foregroundColor: StormModeStatus.shared.isOn ? UIColor.white : UIColor.blackText,
            .font: OpenSans.bold.of(size: 18)
        ]
        
        setNeedsStatusBarAppearanceUpdate()
    }
}
