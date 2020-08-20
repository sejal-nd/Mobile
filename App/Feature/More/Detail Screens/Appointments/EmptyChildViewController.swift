//
//  EmptyChildViewController.swift
//  BGE
//
//  Created by Cody Dillon on 11/6/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class EmptyChildViewController: UIViewController, IndicatorInfoProvider {

    override func viewDidLoad() {
        super.viewDidLoad()
        // do nothing
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "")
    }
}
