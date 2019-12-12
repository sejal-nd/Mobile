//
//  GiftCollectionViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/11/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class GiftCollectionViewController: UICollectionViewController, IndicatorInfoProvider {
    
    static func create(withTitle title: String) -> GiftCollectionViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "GiftCollection") as! GiftCollectionViewController
        vc.title = title
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        var indicator = IndicatorInfo(title: title)
        return indicator
    }
    



}
