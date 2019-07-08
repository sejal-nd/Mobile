//
//  UINavigationController+Style.swift
//  BGE
//
//  Created by Joseph Erlandson on 9/5/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UINavigationController {
    func styleNavbar() {
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

        setNavigationBarHidden(false, animated: true)
    }
}
