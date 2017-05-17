//
//  MainBaseNavigationController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MainBaseNavigationController: UINavigationController {
    
    var storyboardName: String! // Defined as runtime attribute in Main.storyboard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setWhiteNavBar()
        
        if storyboardName != nil {
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            let rootViewController = storyboard.instantiateInitialViewController()
            setViewControllers([rootViewController!], animated: false)
        }
    }
    
    func setWhiteNavBar() {
        navigationBar.barStyle = .default
        navigationBar.barTintColor = .white
        navigationBar.tintColor = .actionBlue
        navigationBar.isTranslucent = false
        
        // Removes the bottom border line:
        //navigationBar.setBackgroundImage(UIImage(), for: .default)
        //navigationBar.shadowImage = UIImage()
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.blackText,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navigationBar.titleTextAttributes = titleDict
        
        setNeedsStatusBarAppearanceUpdate()
        
        setNavigationBarHidden(false, animated: true)
    }
    
    func setColoredNavBar() {
        navigationBar.barStyle = .black
        navigationBar.barTintColor = .primaryColor
        navigationBar.tintColor = .white
        navigationBar.isTranslucent = false
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navigationBar.titleTextAttributes = titleDict
        
        setNeedsStatusBarAppearanceUpdate()
        
        setNavigationBarHidden(false, animated: true)
    }
    
}
