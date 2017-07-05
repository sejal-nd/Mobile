//
//  PaymentConfirmationViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 7/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class PaymentConfirmationViewController: UIViewController {
    
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var navBarTitleLabel: UILabel!
    @IBOutlet weak var confirmationLabel: UILabel!
    @IBOutlet weak var paymentDateLabel: UILabel!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    
    @IBOutlet weak var paymentDateView: UIView!
    @IBOutlet weak var totalAmountView: UIView!
    
    @IBOutlet weak var autoPayView: UIStackView!
    @IBOutlet weak var billMatrixView: UIStackView!

    @IBOutlet weak var enrollAutoPayButton: SecondaryButton!
    
    var presentingNavController: UINavigationController! // Passed from ReviewPaymentViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        xButton.tintColor = .actionBlue
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")

        navBarTitleLabel.textColor = .blackText
        navBarTitleLabel.text = NSLocalizedString("Payment Confirmation", comment: "")
        
        paymentDateView.backgroundColor = .softGray
        totalAmountView.backgroundColor = .softGray
        
        //TODO: hide/show this
        autoPayView.isHidden = true
        billMatrixView.isHidden = true
        
        enrollAutoPayButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
    }

    @IBAction func onXButtonPress() {
        for vc in presentingNavController.viewControllers {
            guard let dest = vc as? BillViewController else {
                continue
            }
            presentingNavController.popToViewController(dest, animated: false)
            break
        }
        presentingNavController.setNavigationBarHidden(true, animated: true) // Fixes bad dismiss animation
        presentingNavController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onEnrollInAutoPayPress() {
        for vc in presentingNavController.viewControllers {
            guard let dest = vc as? BillViewController else {
                continue
            }
            presentingNavController.popToViewController(dest, animated: false)
            dest.navigateToAutoPay()
            break
        }
        presentingNavController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onPrivacyPolicyPress(_ sender: Any) {
        
        dLog(message: "privacy policy press")
    }


}
