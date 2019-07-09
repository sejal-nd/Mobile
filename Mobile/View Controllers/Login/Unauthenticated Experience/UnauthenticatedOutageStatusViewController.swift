//
//  UnauthenticatedOutageStatusViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 9/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UnauthenticatedOutageStatusViewController: UIViewController {

    @IBOutlet weak var accountInfoBar: AccountInfoBar!
    @IBOutlet weak var outageStatusButton: OutageStatusButton!
    @IBOutlet weak var reportOutageButton: DisclosureButton!
    @IBOutlet weak var viewOutageMapButton: DisclosureButton!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
    
    let disposeBag = DisposeBag()
    
    var analyticsSource: AnalyticsOutageSource!
    var viewModel: UnauthenticatedOutageViewModel! // Passed from screen that pushes this
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Outage", comment: "")
        
        accountInfoBar.update(accountNumber: viewModel.selectedOutageStatus!.maskedAccountNumber, address: viewModel.selectedOutageStatus!.maskedAddress)
        
        outageStatusButton.delegate = self
        
        let currentOutageStatus = viewModel.selectedOutageStatus!
        if currentOutageStatus.activeOutage {
            outageStatusButton.setOutageState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else { // Power is on
            outageStatusButton.setPowerOnState()
        }
        
        if let _ = viewModel.reportedOutage {
            reportOutageButton.setDetailLabel(text: viewModel.outageReportedDateString, checkHidden: false)
            reportOutageButton.accessibilityLabel = String.localizedStringWithFormat("Report outage. %@", viewModel.outageReportedDateString)
        } else {
            reportOutageButton.setDetailLabel(text: "", checkHidden: true)
            reportOutageButton.accessibilityLabel = NSLocalizedString("Report outage", comment: "")
        }
        
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.linkTapDelegate = self
        
        RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                guard let this = self else { return }
                this.outageStatusButton.setReportedState(estimatedRestorationDateString: this.viewModel.estimatedRestorationDateString)
                this.reportOutageButton.setDetailLabel(text: this.viewModel.outageReportedDateString, checkHidden: false)
                this.reportOutageButton.accessibilityLabel = String.localizedStringWithFormat("Report outage. %@", this.viewModel.outageReportedDateString)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch analyticsSource {
        case .report?:
            Analytics.log(event: .reportAnOutageUnAuthOutScreen)
        case .status?:
            Analytics.log(event: .outageStatusUnAuthComplete)
        default:
            break
        }
    }
    
    @IBAction func onReportOutagePress() {
        performSegue(withIdentifier: "reportOutageSegue", sender: self)
    }
    
    @IBAction func onViewOutageMapPress() {
        Analytics.log(event: .viewOutageUnAuthMenu)
        performSegue(withIdentifier: "outageMapSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReportOutageViewController {
            vc.unauthenticatedExperience = true
            vc.viewModel.outageStatus = viewModel.selectedOutageStatus!
            vc.viewModel.accountNumber = viewModel.accountNumber.value.isEmpty ? nil : viewModel.accountNumber.value
            if let phone = viewModel.selectedOutageStatus!.contactHomeNumber {
                vc.viewModel.phoneNumber.value = phone
            }
            
            RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
                .drive(onNext: { [weak self] in
                    guard let this = self else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                        this.view.showToast(NSLocalizedString("Outage report received", comment: ""))
                        Analytics.log(event: .reportAnOutageUnAuthComplete)
                    })
                })
                .disposed(by: vc.disposeBag)
        } else if let vc = segue.destination as? OutageMapViewController {
            vc.unauthenticatedExperience = true
        }
    }


}

extension UnauthenticatedOutageStatusViewController: OutageStatusButtonDelegate {
    func outageStatusButtonWasTapped(_ outageStatusButton: OutageStatusButton) {
        Analytics.log(event: .outageStatusUnAuthStatusButton)
        if let message = viewModel.selectedOutageStatus!.outageDescription {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}

extension UnauthenticatedOutageStatusViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        Analytics.log(event: .outageScreenUnAuthEmergencyPhone)
    }
}
