//
//  EmptyViewController.swift
//  BGE
//
//  Created by Cody Dillon on 11/1/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class EmptyStateViewController: UIViewController {
        
    @IBOutlet private weak var emptyStateImageView: UIImageView!
    @IBOutlet private weak var emptyStateLabel: UILabel!
    
    private var emptyStateMessage: String
    private var emptyStateImageName: String
    
    required init(message: String, imageName: String) {
        self.emptyStateMessage = message
        self.emptyStateImageName = imageName
        super.init(nibName: "EmptyStateView", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyStateLabel.text = emptyStateMessage
        emptyStateImageView.image = UIImage(named: emptyStateImageName)
    }
}

extension EmptyStateViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        var indicator = IndicatorInfo(title: "")
        indicator.accessibilityLabel = ""
        return indicator
    }
}
