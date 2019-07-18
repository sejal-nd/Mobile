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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        commonInit()
    }
    
    private func commonInit() {
        navigationBar.barStyle = .default
        
        let color: UIColor = StormModeStatus.shared.isOn ? .stormModeBlack : .white
        navigationBar.backgroundColor = color
        navigationBar.barTintColor = color
        navigationBar.tintColor = .actionBlue
        navigationBar.isTranslucent = false
        
        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.shadowImage = UIColor.primaryColor.image()
        
        navigationBar.largeTitleTextAttributes = [
            .foregroundColor: StormModeStatus.shared.isOn ? UIColor.white : UIColor.blackText,
            .font: OpenSans.bold.of(size: 20)
        ]
        navigationItem.largeTitleDisplayMode = .always
        navigationBar.prefersLargeTitles = true
        
        navigationBar.titleTextAttributes = [
            .foregroundColor: StormModeStatus.shared.isOn ? UIColor.white : UIColor.blackText,
            .font: OpenSans.bold.of(size: 18)
        ]
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // If presenting an InfoModalViewController or WebViewController, first wrap it in a
    // LargeTitleNavigationController so that we get the styled large title nav bar
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if viewControllerToPresent is InfoModalViewController ||
            viewControllerToPresent is WebViewController {
            let newNavController = LargeTitleNavigationController(rootViewController: viewControllerToPresent)
            newNavController.modalPresentationStyle = .formSheet
            present(newNavController, animated: flag, completion: completion)
        } else {
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }
    }
}