//
//  UnauthenticatedOutageStatusViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 9/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UnauthenticatedOutageStatusViewController: UIViewController {

    @IBOutlet weak var accountInfoBar: AccountInfoBar!
    @IBOutlet weak var outageStatusButton: OutageStatusButton!
    @IBOutlet weak var reportOutageButton: DisclosureButton!
    @IBOutlet weak var viewOutageMapButton: DisclosureButton!
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    // TODO: ADD THE GRADIENT BACKGROUND
    
    var viewModel: UnauthenticatedOutageViewModel! // Passed from screen that pushes this
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Outage", comment: "")
        
        accountInfoBar.update(accountNumber: viewModel.selectedOutageStatus!.maskedAccountNumber, address: viewModel.selectedOutageStatus!.maskedAddress)
        
        outageStatusButton.delegate = self
        
        let currentOutageStatus = viewModel.selectedOutageStatus!
        if viewModel.reportedOutage != nil {
            outageStatusButton.setReportedState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else if currentOutageStatus.activeOutage {
            outageStatusButton.setOutageState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else if currentOutageStatus.flagFinaled || currentOutageStatus.flagNoPay || currentOutageStatus.flagNonService {
            // TODO: Handle with modals on the previous screen
            //outageStatusButton.setIneligibleState(flagFinaled: currentOutageStatus.flagFinaled, nonPayFinaledMessage: viewModel.accountNonPayFinaledMessage)
        } else { // Power is on
            outageStatusButton.setPowerOnState()
        }
        
        // Update the Report Outage button
        if viewModel.reportedOutage != nil {
            reportOutageButton.setDetailLabel(text: viewModel.outageReportedDateString, checkHidden: false)
            reportOutageButton.accessibilityLabel = String(format: NSLocalizedString("Report outage. %@", comment: ""), viewModel.outageReportedDateString)
        } else {
            reportOutageButton.setDetailLabel(text: "", checkHidden: true)
            reportOutageButton.accessibilityLabel = NSLocalizedString("Report outage", comment: "")
        }
        
        // Disable bottom buttons if account is finaled or not paid
        let bottomButtonsEnabled = !currentOutageStatus.flagNoPay && !currentOutageStatus.flagFinaled && !currentOutageStatus.flagNonService
        reportOutageButton.isEnabled = bottomButtonsEnabled
        viewOutageMapButton.isEnabled = bottomButtonsEnabled
        
        footerTextView.font = SystemFont.regular.of(textStyle: .headline)
        footerTextView.textContainerInset = .zero
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.text = viewModel.footerText
        footerTextView.delegate = self
        
    }


}

extension UnauthenticatedOutageStatusViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        //Analytics().logScreenView(AnalyticsPageView.OutageAuthEmergencyCall.rawValue)
        return true
    }
}

extension UnauthenticatedOutageStatusViewController: OutageStatusButtonDelegate {
    func outageStatusButtonWasTapped(_ outageStatusButton: OutageStatusButton) {
        //Analytics().logScreenView(AnalyticsPageView.OutageStatusDetails.rawValue)
        if viewModel.selectedOutageStatus!.flagNoPay && Environment.sharedInstance.opco != .bge  {
            tabBarController?.selectedIndex = 1 // Jump to Bill tab
            Analytics().logScreenView(AnalyticsPageView.OutageStatusOfferComplete.rawValue)
        } else {
            if let message = viewModel.selectedOutageStatus!.outageDescription {
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                Analytics().logScreenView(AnalyticsPageView.OutageStatusOfferComplete.rawValue)
            }
        }
    }
}
