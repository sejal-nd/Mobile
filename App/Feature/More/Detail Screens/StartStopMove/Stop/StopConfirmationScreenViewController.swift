//
//  StopConfirmationScreenViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 23/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import MessageUI

class StopConfirmationScreenViewController: UIViewController {

    @IBOutlet weak var confirmationStateMessageLabel: UILabel!
    @IBOutlet weak var stopServiceDateStaticLabel: UILabel!
    @IBOutlet weak var stopServiceDateTimeLabel: UILabel!
    @IBOutlet weak var stopServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var stopServiceAddressLabel: UILabel!
    @IBOutlet weak var finalBillStaticLabel: UILabel!
    @IBOutlet weak var finalBillLabel: UILabel!
    @IBOutlet weak var nextStepsDescriptionLabel: UILabel!
    @IBOutlet weak var helplineDescriptionTextView: UITextView!
    @IBOutlet weak var accountNumberStaticLabel: UILabel!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var serviceRequestView: UIView!
    @IBOutlet weak var accountNumberView: UIView!
    
    var viewModel: StopConfirmationScreenViewModel!
            
    override func viewDidLoad() {
        
        super.viewDidLoad()
        intialUISetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseUtility.logScreenView(.stopConfirmationView(className: self.className))
    }
    
    private func intialUISetup() {
        
        navigationSetup()
        fontStyling()
        
        serviceRequestView.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        accountNumberView.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        
        dataBinding()
    }
    
    private func fontStyling() {
        
        confirmationStateMessageLabel.font = ExelonFont.semibold.of(textStyle: .title3)
        stopServiceDateStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        finalBillStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountNumberStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountNumberLabel.font = SystemFont.semibold.of(size: 15.0)
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
        
        stopServiceDateTimeLabel.text = viewModel.getStopServiceDate()
        finalBillLabel.text = viewModel.getFinalBillAddress()
        stopServiceAddressLabel.text = viewModel.getStopServiceAddress().getValidISUMAddress()
        nextStepsDescriptionLabel.text = viewModel.getNextStepDescription()
        accountNumberLabel.text = viewModel.stopServiceResponse.accountNumber
        let helplineDescription = "If you have questions or need to make changes to your request, please email myhomerep@bge.com and provide your account number. We will respond within 24-48 business hours."
        let range = (helplineDescription as NSString).range(of: "myhomerep@bge.com")
        let attributedString = NSMutableAttributedString(string: helplineDescription)
        attributedString.addAttribute(NSAttributedString.Key.link, value: "mailto:", range: range)
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.neutralDark], range: NSRange(location: 0, length: helplineDescription.count))
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.primaryBlue], range: range)
        helplineDescriptionTextView.attributedText = attributedString
        helplineDescriptionTextView.linkTextAttributes = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.primaryBlue]
        helplineDescriptionTextView.isUserInteractionEnabled = true
        helplineDescriptionTextView.isEditable = false
        helplineDescriptionTextView.textContainerInset = .zero
        helplineDescriptionTextView.delegate = self
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
}

extension StopConfirmationScreenViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if (url.scheme?.contains("mailto")) ?? false {
            openMFMail()
        }
        return false
    }
}

extension StopConfirmationScreenViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
