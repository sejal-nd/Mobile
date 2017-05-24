//
//  AddCreditCardViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AddCreditCardViewController: UIViewController {
    
    var cardIOViewController: CardIOPaymentViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCardIO()
    }
    
    func configureCardIO() {
        CardIOUtilities.preloadCardIO() // Speeds up subsequent launch
        cardIOViewController = CardIOPaymentViewController.init(paymentDelegate: self)
        cardIOViewController.disableManualEntryButtons = true
        cardIOViewController.guideColor = UIColor.successGreen
        cardIOViewController.hideCardIOLogo = true
        cardIOViewController.collectCardholderName = false
        cardIOViewController.collectExpiry = false
        cardIOViewController.collectCVV = false
        cardIOViewController.collectPostalCode = false
        cardIOViewController.navigationBarStyle = .black
        cardIOViewController.navigationBarTintColor = .primaryColor
        cardIOViewController.navigationBar.isTranslucent = false
        cardIOViewController.navigationBar.tintColor = .white
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        cardIOViewController.navigationBar.titleTextAttributes = titleDict
    }
    
    @IBAction func onCardIOButtonPress() {
        present(cardIOViewController!, animated: true, completion: nil)
    }
}

extension AddCreditCardViewController: CardIOPaymentViewControllerDelegate {
    func userDidCancel(_ paymentViewController: CardIOPaymentViewController!) {
        cardIOViewController.dismiss(animated: true, completion: nil)
    }
    
    func userDidProvide(_ cardInfo: CardIOCreditCardInfo!, in paymentViewController: CardIOPaymentViewController!) {
        cardIOViewController.dismiss(animated: true, completion: nil)
        print("GOT EM \(cardInfo.cardNumber)")
    }
}
