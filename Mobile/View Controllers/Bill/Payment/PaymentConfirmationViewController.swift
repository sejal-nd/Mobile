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

    
    @IBOutlet weak var paymentInfoView: UIView!
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateValueLabel: UILabel!
    @IBOutlet weak var amountPaidTextLabel: UILabel!
    @IBOutlet weak var amountPaidValueLabel: UILabel!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet weak var autoPayView: UIStackView!
    @IBOutlet weak var billMatrixView: UIStackView!

    @IBOutlet weak var autoPayLabel: UILabel!
    @IBOutlet weak var enrollAutoPayButton: SecondaryButton!
    
    var presentingNavController: UINavigationController! // Passed from ReviewPaymentViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        xButton.tintColor = .actionBlue
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")

        navBarTitleLabel.textColor = .blackText
        navBarTitleLabel.text = NSLocalizedString("Payment Confirmation", comment: "")
        
        confirmationLabel.textColor = .blackText
        confirmationLabel.font = OpenSans.regular.of(textStyle: .body)
        confirmationLabel.text = NSLocalizedString("Thank you for your payment. A confirmation email will be sent to your shortly.", comment: "")
        
        convenienceFeeLabel.textColor = .blackText
        convenienceFeeLabel.font = OpenSans.regular.of(textStyle: .footnote)
        convenienceFeeLabel.text = NSLocalizedString("A $2.35 convenience fee will be applied by Bill Matrix, our payment partner.", comment: "")
        convenienceFeeLabel.isHidden = true
        
        paymentInfoView.backgroundColor = .softGray
        
        paymentDateTextLabel.textColor = .blackText
        paymentDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateValueLabel.textColor = .blackText
        paymentDateValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountPaidTextLabel.textColor = .blackText
        amountPaidTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountPaidTextLabel.text = NSLocalizedString("Amount Paid", comment: "")
        amountPaidValueLabel.textColor = .blackText
        amountPaidValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        //TODO: hide/show this
//        autoPayView.isHidden = true
//        billMatrixView.isHidden = true
        
        autoPayLabel.textColor = .deepGray
        autoPayLabel.font = SystemFont.regular.of(textStyle: .footnote)
        autoPayLabel.text = NSLocalizedString("Would you like to set up Automatic Payments?", comment: "")
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
