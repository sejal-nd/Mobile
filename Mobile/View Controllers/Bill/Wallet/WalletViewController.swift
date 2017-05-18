//
//  WalletViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class WalletViewController: UIViewController {
    
    // Empty state stuff
    @IBOutlet weak var emptyStateScrollView: UIScrollView!
    @IBOutlet weak var choosePaymentAccountLabel: UILabel!
    @IBOutlet weak var creditCardButton: ButtonControl!
    @IBOutlet weak var creditCardButtonLabel: UILabel!
    @IBOutlet weak var bankButton: ButtonControl!
    @IBOutlet weak var bankButtonLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    // Non-empty state stuff
    @IBOutlet weak var tableView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("My Wallet", comment: "")
        view.backgroundColor = .softGray
        
        choosePaymentAccountLabel.textColor = .blackText
        choosePaymentAccountLabel.text = NSLocalizedString("Choose a payment account:", comment: "")
        
        creditCardButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        creditCardButton.layer.cornerRadius = 10
        creditCardButtonLabel.textColor = .blackText
        creditCardButtonLabel.text = NSLocalizedString("Credit/Debit Card", comment: "")
        
        bankButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        bankButton.layer.cornerRadius = 10
        bankButtonLabel.textColor = .blackText
        bankButtonLabel.text = NSLocalizedString("Bank Account", comment: "")
        
        bottomLabel.textColor = .blackText
        switch Environment.sharedInstance.opco {
        case .comEd, .peco:
            bottomLabel.text = NSLocalizedString("Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        case .bge:
            bottomLabel.text = NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Small business customers cannot use VISA. Bank account verification may take up to 3 business days, at which point we will notify you via email of its activatio", comment: "")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }

}
