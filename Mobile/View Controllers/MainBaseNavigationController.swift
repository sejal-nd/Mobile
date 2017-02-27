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
        
        //navigationBar.barStyle = .black
        navigationBar.barTintColor = .white
        navigationBar.tintColor = .textButtonColor
        
        let titleDict: [String: Any] = [NSForegroundColorAttributeName: UIColor.darkJungleGreen]
        navigationBar.titleTextAttributes = titleDict
        
        setNeedsStatusBarAppearanceUpdate()
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let rootViewController = storyboard.instantiateInitialViewController()
        setViewControllers([rootViewController!], animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
