//
//  MoveServiceConfirmationViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 22/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import MessageUI

class MoveServiceConfirmationViewController: UIViewController {
    
    @IBOutlet weak var moveStatusLabel: UILabel!
    
    @IBOutlet weak var stopServiceView: UIView!
    @IBOutlet weak var stopServiceDateStaticLabel: UILabel!
    @IBOutlet weak var stopServiceDateLabel: UILabel!
    @IBOutlet weak var stopServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var stopServiceAddressLabel: UILabel!
    
    @IBOutlet weak var startServiceView: UIView!
    @IBOutlet weak var startServiceDateStaticLabel: UILabel!
    @IBOutlet weak var startServiceDateLabel: UILabel!
    @IBOutlet weak var startServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var startServiceAddressLabel: UILabel!

    @IBOutlet weak var thirdPartySupplierStackView: UIStackView!
    @IBOutlet weak var thirdPartySupplierInnerContentView: UIView!
    @IBOutlet weak var thirdPartySupplierView: UIView!
    @IBOutlet weak var thirdPartySupplierStatusLabel: UILabel!
    @IBOutlet weak var thirdPartyInfoButton: UIButton!
    
    @IBOutlet weak var nextStepStackView: UIStackView!
    @IBOutlet weak var billingAddressView: UIView!
    @IBOutlet weak var billingDescriptionLabel: UILabel!
    @IBOutlet weak var billingAddressLabel: UILabel!

    @IBOutlet weak var billChargeView: UIView!
    @IBOutlet weak var billChargesStaticLabel: UILabel!
    @IBOutlet weak var billChargesLabel: UILabel!
    @IBOutlet weak var helplineDescriptionTextView: UITextView!

    @IBOutlet weak var accountNumberView: UIView!
    @IBOutlet weak var accountNumberStaticLabel: UILabel!
    @IBOutlet weak var accountNumberLabel: UILabel!
    
    var viewModel:MoveServiceConfirmationViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        intialSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if viewModel.isUnauth {
            FirebaseUtility.logScreenView(.unauthMoveConfirmationView(className: self.className))
        } else {
            FirebaseUtility.logScreenView(.moveConfirmationView(className: self.className))
        }
    }
    
    private func intialSetup() {
        
        navigationSetup()
        fontStyling()
        dataBinding()
    }
    
    private func fontStyling() {
        
        moveStatusLabel.font = OpenSans.semibold.of(textStyle: .title3)
        stopServiceDateStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        startServiceDateStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        startServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        billingDescriptionLabel.font = SystemFont.regular.of(textStyle: .footnote)
        billChargesStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountNumberStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountNumberLabel.font = SystemFont.semibold.of(size: 15.0)

        for view in [stopServiceView, startServiceView, billingAddressView, billChargeView, accountNumberView, thirdPartySupplierInnerContentView] {
            view?.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        }
    }
    
    @IBAction func onBillChargesToolTip(_ sender: Any) {
        
        let alertViewController = InfoAlertController(title: NSLocalizedString("Service Application Charge", comment: ""),
                                                      message: "At the start of service, BGE assesses a non-refundable $20 fee that covers initial administrative start-up costs. This charge will appear on your bill.")
        self.present(alertViewController, animated: true)
    }
    
    private func navigationSetup() {
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundImage = UIImage()
        appearance.backgroundColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        navigationItem.hidesBackButton = false
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_close"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(StopConfirmationScreenViewController.back(sender:)))
        navigationItem.leftBarButtonItem = newBackButton
    }
    
    @objc func back(sender: UIBarButtonItem) {
        
        dismiss(animated: true, completion: nil)
    }
    
    private func dataBinding() {
        
        let helplineDescription = "If you have questions or need to make changes to your request, please email myhomerep@bge.com and provide your account number. We will respond within 24-48 business hours."
        let range = (helplineDescription as NSString).range(of: "myhomerep@bge.com")
        let attributedString = NSMutableAttributedString(string: helplineDescription)
        attributedString.addAttribute(NSAttributedString.Key.link, value: "mailto:", range: range)
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.deepGray], range: NSRange(location: 0, length: helplineDescription.count))
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.actionBlue], range: range)
        helplineDescriptionTextView.attributedText = attributedString
        helplineDescriptionTextView.linkTextAttributes = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.actionBlue]
        helplineDescriptionTextView.isUserInteractionEnabled = true
        helplineDescriptionTextView.isEditable = false
        helplineDescriptionTextView.textContainerInset = .zero
        helplineDescriptionTextView.delegate = self

        stopServiceDateLabel.text = viewModel.moveServiceResponse.stopDate + ", 8:00 a.m."
        stopServiceAddressLabel.text = viewModel.getStopServiceAddress().getValidISUMAddress()
        startServiceDateLabel.text = viewModel.moveServiceResponse.startDate + ", 8:00 a.m. -  6:00 p.m."
        startServiceAddressLabel.text = viewModel.getStartServiceAddress().getValidISUMAddress()
        billingDescriptionLabel.text = viewModel.getBillingDescription()
        billingAddressLabel.text = viewModel.getBillingAddress()
        accountNumberLabel.text = viewModel.moveServiceResponse.accountNumber
        nextStepStackView.isHidden = viewModel.moveServiceResponse.isResolved ?? false
        
        if viewModel.shouldShowSeamlessMove {
            thirdPartyInfoButton.setTitle("", for: .normal)
            let thirdPartySupplierStatusText: String
            if viewModel.transferEligibility == .eligible {
                if viewModel.transferOption == .transfer {
                    thirdPartySupplierStatusText = "Transfer to Start Service Address"
                } else {
                    thirdPartySupplierStatusText = "Discontinued"
                }
            } else {
                thirdPartySupplierStatusText = "Discontinued"
            }
            
            thirdPartySupplierStatusLabel.text = thirdPartySupplierStatusText
            
        } else {
            thirdPartySupplierStackView.isHidden = true
        }
    }
    
    func openMFMail() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["myhomerep@bge.com"])
            mailComposer.setMessageBody("", isHTML: false)
            present(mailComposer, animated: true, completion: nil)
        }
    }
    
    @IBAction func thirdPartyToolTipPress(_ sender: Any) {
        let modalText: String
        
        if viewModel.transferEligibility == .eligible {
            if viewModel.transferOption == .transfer {
                modalText = "You have indicated that we should carry forward your Third Party Electric Supplier Agreement.\n\nFor any questions or concerns, please contact your Third Party Supplier.\n\nYour retail electric supplier’s phone number is provided in the Electric Supply Charges portion of your BGE bill."
            } else {
                modalText = "You have chosen to discontinue your Third Party Electric Supplier Agreement. This will be reflected in your account after your new service start date.\n\nFor any questions or concerns, please contact your Third Party Supplier.\n\nYour retail electric supplier’s phone number is provided in the Electric Supply Charges portion of your BGE bill."
            }
        } else {
            modalText = "Your Third Party Supplier electric agreement will be discontinued. This will be reflected in your account after your new start service date.\n\nFor any questions or concerns, please contact your Third Party Supplier.\n\nYour retail electric supplier’s phone number is provided in the Electric Supply Charges portion of your BGE bill."
        }
        
        
        let infoModal = InfoAlertController(title: "Third Party Supplier Update", message: modalText)
        self.navigationController?.present(infoModal, animated: true, completion: nil)
    }
}

extension MoveServiceConfirmationViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if (url.scheme?.contains("mailto")) ?? false {
            openMFMail()
        }
        return false
    }
}

extension MoveServiceConfirmationViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
}
