//
//  MoveServiceConfirmationViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 22/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

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

    @IBOutlet weak var nextStepStackView: UIStackView!
    @IBOutlet weak var billingAddressView: UIView!
    @IBOutlet weak var billingDescriptionLabel: UILabel!
    @IBOutlet weak var billingAddressLabel: UILabel!

    @IBOutlet weak var billChargeView: UIView!
    @IBOutlet weak var billChargesStaticLabel: UILabel!
    @IBOutlet weak var billChargesLabel: UILabel!
    @IBOutlet weak var helplineDescriptionLabel: UILabel!

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
        FirebaseUtility.logScreenView(.moveConfirmationView(className: self.className))
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
        accountNumberLabel.font = SystemFont.semibold.of(textStyle: .footnote)

        for view in [stopServiceView, startServiceView, billingAddressView, billChargeView, accountNumberView] {
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
        
        let helplineDescription = "If you have any questions, please email myhomerep@bge.com and provide your account number. We will respond within 24-48 business hours."
        let range = (helplineDescription as NSString).range(of: "myhomerep@bge.com")
        let attributedString = NSMutableAttributedString(string: helplineDescription)
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.deepGray], range: NSRange(location: 0, length: helplineDescription.count))
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.actionBlue], range: range)
        helplineDescriptionLabel.attributedText = attributedString
        
        stopServiceDateLabel.text = viewModel.moveServiceResponse.stopDate
        stopServiceAddressLabel.text = viewModel.getStopServiceAddress()
        startServiceDateLabel.text = viewModel.moveServiceResponse.startDate
        startServiceAddressLabel.text = viewModel.getStartServiceAddress()
        billingDescriptionLabel.text = viewModel.getBillingDescription()
        billingAddressLabel.text = viewModel.getBillingAddress()
        accountNumberLabel.text = viewModel.moveServiceResponse.accountNumber
        nextStepStackView.isHidden = viewModel.moveServiceResponse.isResolved ?? false
    }
}