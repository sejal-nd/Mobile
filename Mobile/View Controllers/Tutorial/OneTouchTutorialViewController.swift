//
//  OneTouchTutorialViewController.swift
//  Mobile
//
//  Created by Sam Francis on 9/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class OneTouchTutorialViewController: TutorialModalViewController {
    
    init() {
        let slides = [
            (
                NSLocalizedString("Set Up Default Payment Account", comment: ""),
                NSLocalizedString("You can easily pay your bill in full from the Home screen by setting a payment account as default.", comment: ""),
                "otp_step1"
            ),
            (
                NSLocalizedString("Tap On My Wallet", comment: ""),
                NSLocalizedString("Navigate to the Bill screen and tap \"My Wallet.\" You can also tap the \"Set a default payment account\" button on Home.", comment: ""),
                "otp_step2"
            ),
            (
                NSLocalizedString("Turn On The Default Toggle", comment: ""),
                NSLocalizedString("Create or edit a payment account and turn on the \"Default Payment Account\" toggle.", comment: ""),
                "otp_step3")
            ,
            (
                NSLocalizedString("Success!", comment: ""),
                NSLocalizedString("You can now easily pay from the Home screen. This type of payment cannot be canceled and will pay your account balance in full.", comment: ""),
                "otp_step4"
            )
            ]
            .map(TutorialSlide.init)
        
        super.init(slides: slides)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
