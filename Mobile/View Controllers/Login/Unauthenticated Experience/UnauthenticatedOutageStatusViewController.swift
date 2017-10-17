//
//  UnauthenticatedOutageStatusViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 9/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UnauthenticatedOutageStatusViewController: UIViewController {

    @IBOutlet weak var gradientBackground: UIView!
    @IBOutlet weak var accountInfoBar: AccountInfoBar!
    @IBOutlet weak var outageStatusButton: OutageStatusButton!
    @IBOutlet weak var reportOutageButton: DisclosureButton!
    @IBOutlet weak var viewOutageMapButton: DisclosureButton!
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    var gradientLayer: CAGradientLayer!
    
    var analyticsSource: AnalyticsOutageSource!
    var viewModel: UnauthenticatedOutageViewModel! // Passed from screen that pushes this
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Outage", comment: "")
        
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientBackground.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 244/255, green: 246/255, blue: 247/255, alpha: 1).cgColor,
            UIColor(red: 240/255, green: 242/255, blue: 243/255, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientBackground.layer.addSublayer(gradientLayer)
        
        accountInfoBar.update(accountNumber: viewModel.selectedOutageStatus!.maskedAccountNumber, address: viewModel.selectedOutageStatus!.maskedAddress)
        
        outageStatusButton.delegate = self
        
        let currentOutageStatus = viewModel.selectedOutageStatus!
        if currentOutageStatus.activeOutage {
            outageStatusButton.setOutageState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else { // Power is on
            outageStatusButton.setPowerOnState()
        }
        
        reportOutageButton.setDetailLabel(text: "", checkHidden: true)
        reportOutageButton.accessibilityLabel = NSLocalizedString("Report outage", comment: "")
        
        footerTextView.font = SystemFont.regular.of(textStyle: .headline)
        footerTextView.textContainerInset = .zero
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.text = viewModel.footerText
        footerTextView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch analyticsSource {
        case .Report:
            Analytics().logScreenView(AnalyticsPageView.ReportAnOutageUnAuthOutScreen.rawValue)
        case .Status:
            Analytics().logScreenView(AnalyticsPageView.OutageStatusUnAuthComplete.rawValue)
        default:
            break
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientBackground.frame
    }
    
    @IBAction func onReportOutagePress() {
        performSegue(withIdentifier: "reportOutageSegue", sender: self)
    }
    
    @IBAction func onViewOutageMapPress() {
        Analytics().logScreenView(AnalyticsPageView.ViewOutageUnAuthMenu.rawValue)
        performSegue(withIdentifier: "outageMapSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReportOutageViewController {
            vc.unauthenticatedExperience = true
            vc.viewModel.outageStatus = viewModel.selectedOutageStatus!
            if let phone = viewModel.selectedOutageStatus!.contactHomeNumber {
                vc.viewModel.phoneNumber.value = phone
            }
            vc.delegate = self
        } else if let vc = segue.destination as? OutageMapViewController {
            vc.unauthenticatedExperience = true
        }
    }


}

extension UnauthenticatedOutageStatusViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        Analytics().logScreenView(AnalyticsPageView.OutageStatusUnAuthAcctValEmergencyPhone.rawValue)
        return true
    }
}

extension UnauthenticatedOutageStatusViewController: OutageStatusButtonDelegate {
    func outageStatusButtonWasTapped(_ outageStatusButton: OutageStatusButton) {
        Analytics().logScreenView(AnalyticsPageView.OutageStatusUnAuthStatusButton.rawValue)
        if let message = viewModel.selectedOutageStatus!.outageDescription {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            //Analytics().logScreenView(AnalyticsPageView.OutageStatusOfferComplete.rawValue)
        }
    }
}

extension UnauthenticatedOutageStatusViewController: ReportOutageViewControllerDelegate {
    
    func reportOutageViewControllerDidReportOutage(_ reportOutageViewController: ReportOutageViewController, reportedOutage: ReportedOutageResult?) {
        viewModel.reportedOutage = reportedOutage
        outageStatusButton.setReportedState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        reportOutageButton.setDetailLabel(text: viewModel.outageReportedDateString, checkHidden: false)
        reportOutageButton.accessibilityLabel = String(format: NSLocalizedString("Report outage. %@", comment: ""), viewModel.outageReportedDateString)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Outage report received", comment: ""))
            Analytics().logScreenView(AnalyticsPageView.ReportAnOutageUnAuthComplete.rawValue)
        })
    }
    
}
