//
//  GiftsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/20/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class GiftsViewController: ButtonBarPagerTabStripViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Gifts", comment: "")
        
        buttonBarItemSpec = ButtonBarItemSpec<ButtonBarViewCell>.cellClass(width: { _ in 125 })
        buttonBarView.selectedBar.backgroundColor = .primaryColor
        buttonBarView.backgroundColor = .white
        
        settings.style.buttonBarBackgroundColor = .white
        settings.style.buttonBarMinimumInteritemSpacing = 0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarLeftContentInset = 55
        settings.style.buttonBarRightContentInset = 55
        settings.style.selectedBarBackgroundColor = .white
        settings.style.selectedBarHeight = 4
        settings.style.selectedBarVerticalAlignment = .bottom
        settings.style.buttonBarItemBackgroundColor = .white
        settings.style.buttonBarItemFont = OpenSans.semibold.of(textStyle: .subheadline)
        settings.style.buttonBarItemTitleColor = .middleGray
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        settings.style.buttonBarHeight = 48
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .middleGray
            oldCell?.label.font = OpenSans.regular.of(textStyle: .subheadline)
            newCell?.label.textColor = .actionBlue
            newCell?.label.font = OpenSans.semibold.of(textStyle: .subheadline)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let backgrounds = GiftCollectionViewController.create(withTitle: "Backgrounds")
        let hats = GiftCollectionViewController.create(withTitle: "Hats")
        let accessories = GiftCollectionViewController.create(withTitle: "Accessories")
        return [backgrounds, hats, accessories]
    }
    

}
