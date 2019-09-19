//
//  SetDefaultPaymentMethodTutorialViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 9/19/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class SetDefaultPaymentMethodTutorialViewController: UIViewController {
    
    init() {
        super.init(nibName: "SetDefaultPaymentMethodTutorialViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Set Default Payment Method", comment: "")
        
        addCloseButton()
    }

}
