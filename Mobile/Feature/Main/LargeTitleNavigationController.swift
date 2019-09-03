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
        navigationBar.barStyle = StormModeStatus.shared.isOn ? .black : .default
        
        let backgroundColor: UIColor = StormModeStatus.shared.isOn ? .stormModeBlack : .white
        let textColor = StormModeStatus.shared.isOn ? UIColor.white : UIColor.blackText
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = backgroundColor
            appearance.titleTextAttributes = [.foregroundColor: textColor]
            appearance.largeTitleTextAttributes = [
                .foregroundColor: textColor,
                .font: OpenSans.semibold.of(size: 24)
            ]
            
            appearance.titleTextAttributes = [
                .foregroundColor: textColor,
                .font: OpenSans.semibold.of(size: 15)
            ]
            
            if StormModeStatus.shared.isOn {
                // No bottom border in Storm Mode
                appearance.shadowImage = UIImage()
            } else {
                appearance.shadowImage = UIColor.primaryColor.navBarShadowImage()
            }
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            navigationBar.setBackgroundImage(nil, for: .default)
            
            if StormModeStatus.shared.isOn {
                // No bottom border in Storm Mode
                navigationBar.shadowImage = UIImage()
            } else {
                navigationBar.shadowImage = UIColor.primaryColor.navBarShadowImage()
            }
            
            navigationBar.largeTitleTextAttributes = [
                .foregroundColor: textColor,
                .font: OpenSans.semibold.of(size: 24)
            ]
            
            navigationBar.titleTextAttributes = [
                .foregroundColor: textColor,
                .font: OpenSans.semibold.of(size: 15)
            ]
            
            setNeedsStatusBarAppearanceUpdate()
        }
        
        navigationItem.largeTitleDisplayMode = .always
        navigationBar.prefersLargeTitles = true
        
        navigationBar.barTintColor = backgroundColor
        navigationBar.tintColor = StormModeStatus.shared.isOn ? .white : .actionBlue
        navigationBar.isTranslucent = false
        
        view.backgroundColor = backgroundColor
        navigationBar.backgroundColor = backgroundColor
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
