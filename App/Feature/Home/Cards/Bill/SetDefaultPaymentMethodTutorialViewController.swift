//
//  SetDefaultPaymentMethodTutorialViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 9/19/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class SetDefaultPaymentMethodTutorialViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    var shouldPushWallet: PublishSubject<Void>?
    
    init() {
        super.init(nibName: "SetDefaultPaymentMethodTutorialViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = true

        title = NSLocalizedString("Set Default Payment Method", comment: "")
        
        addCloseButton()
        
        label.textColor = .deepGray
        label.font = SystemFont.regular.of(textStyle: .body)
        label.text = NSLocalizedString("""
        You can easily pay your bill in full from the Home screen by setting a payment method as default.
        
        1. Create or edit a payment method and check the "Default Payment Method” checkbox. If you had no methods saved, the new one will automatically be your default payment method.

        2. After you save your changes, you can then easily pay from the Home screen. This type of payment cannot be canceled and will pay your account balance in full.
        """, comment: "")
    }
    
    @IBAction func onTakeMeToMyWalletPress() {
        shouldPushWallet?.onNext(())
        dismissModal()
    }

}
