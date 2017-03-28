//
//  MoreSplitViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 3/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MoreSplitViewController: UISplitViewController {
    
    required init?(coder aDecoder: NSCoder) {
        super .init(coder: aDecoder)
        
        let storyboard = UIStoryboard(name: "More", bundle: nil)
        let masterNavController = storyboard.instantiateViewController(withIdentifier: "splitViewMaster")
        let detailNavController = storyboard.instantiateViewController(withIdentifier: "splitViewDetail")
        
        viewControllers = [masterNavController, detailNavController]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        preferredDisplayMode = .allVisible
    }

}

extension MoreSplitViewController: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        return true
    }

}
