//
//  StopConfirmationScreenViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 23/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class StopConfirmationScreenViewController: UIViewController {

    @IBOutlet weak var confirmationStateMessageLabel: UILabel!
    @IBOutlet weak var stopServiceDateStaticLabel: UILabel!
    @IBOutlet weak var stopServiceDateTimeLabel: UILabel!
    @IBOutlet weak var stopServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var stopServiceAddressLabel: UILabel!
    @IBOutlet weak var finalBillStaticLabel: UILabel!
    @IBOutlet weak var finalBillLabel: UILabel!
    @IBOutlet weak var nextStepsDescriptionLabel: UILabel!
    @IBOutlet weak var helplineDescriptionLabel: UILabel!
    @IBOutlet weak var accountNumberStaticLabel: UILabel!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var serviceRequestView: UIView!
    @IBOutlet weak var accountNumberView: UIView!
        
    override func viewDidLoad() {
        
        super.viewDidLoad()
        intialUISetup()
    }
    
    private func intialUISetup() {
        
        navigationSetup()
        fontStyling()
        
        serviceRequestView.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        accountNumberView.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        
        dataBinding()
    }
    
    private func fontStyling() {
        
        confirmationStateMessageLabel.font = OpenSans.semibold.of(textStyle: .title3)
        stopServiceDateStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        finalBillStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountNumberStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
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
    
    // TODO: Dynamic data binding and will cover in stop service submit functionality
    private func dataBinding() {
        
        stopServiceDateTimeLabel.text = "November 19, 2021, 8:00 a.m."
        stopServiceAddressLabel.text = "123 Anywhere Street, Apt. 123 – B Baltimore, MD 21215"
        finalBillLabel.text = "The service address above"
        nextStepsDescriptionLabel.text = "We will disconnect your service remotely through your smart meter. You will not need to be present. Please prepare for your service to be shut off as early as 8 a.m."
        accountNumberLabel.text = "2345678910"
        
        let helplineDescription = "If you have any questions, please email myhomerep@bge.com and provide your account number. We will respond within 24-48 business hours."
        let range = (helplineDescription as NSString).range(of: "myhomerep@bge.com")
        let attributedString = NSMutableAttributedString(string: helplineDescription)
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.actionBlue], range: range)
        helplineDescriptionLabel.attributedText = attributedString
    }
}
