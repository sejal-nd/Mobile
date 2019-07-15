//
//  NewOutageViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

// Ensure we test of all phone sizes + ipad + orientations
class NewOutageViewController: AccountPickerViewController {
    
    enum State {
        case normal
        case loading
        case gasOnly
        case maintenance
        case noNetwork
        case unavailable // what is this state?
    }
    
    // Note create these view controller / revamps last...
    @IBOutlet weak var maintenanceModeContainerView: UIView! // we are going to create a UIViewController for error state, this can be used for all VC's in the future
    @IBOutlet weak var NoNetworkConnectionContainerView: UIView! // enum on error state.
    @IBOutlet weak var loadingContainerView: UIView! // we are going to create a UIViewController for loading, this can be used for all VC's in the future
    @IBOutlet weak var gasOnlyContainerView: UIView!
    @IBOutlet weak var notAvailableContainerView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var outageStatusView: OutageStatusView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView! // may be special text view
    
    private let viewModel = NewOutageViewModel(accountService: ServiceFactory.createAccountService(),
                                            outageService: ServiceFactory.createOutageService(),
                                            authService: ServiceFactory.createAuthenticationService())
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // BEGIN REFACTOR - todo
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        
        // We should move this to a subclass....
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.linkTapDelegate = self

        // END REFACTOR - todo
        
        
        configureState(.loading)
        loadOutageStatus()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
        tableView.sizeFooterToFit()
    }
    
    
    // MARK: - Helper
    
    private func loadOutageStatus() {
        configureState(.unavailable)
//        viewModel.fetchData(onSuccess: { [weak self] outageStatus in
//            guard let `self` = self else { return }
//            if outageStatus.flagGasOnly {
//                self.configureState(.gasOnly)
//            } else {
//                self.configureState(.normal)
//                self.outageStatusView.setOutageStatus(outageStatus,
//                                                      reportedResults: self.viewModel.reportedOutage,
//                                                      hasJustReported: self.viewModel.hasJustReportedOutage)
//            }
//            }, onError: { [weak self] serviceError in
//                if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
//                    self?.configureState(.noNetwork)
//                } else if serviceError.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue {
//                   self?.configureState(.unavailable)
//                }
//            }, onMaintenance: { [weak self] in
//                self?.configureState(.maintenance)
//        })
    }
    
    private func configureState(_ state: State) {
        switch state {
        case .normal:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = true
            NoNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = true
        case .loading:
            loadingContainerView.isHidden = false
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = true
            NoNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = true
        case .gasOnly:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = false
            maintenanceModeContainerView.isHidden = true
            NoNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = true
        case .maintenance:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = false
            NoNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = true
        case .noNetwork:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = true
            NoNetworkConnectionContainerView.isHidden = false
            notAvailableContainerView.isHidden = true
        case .unavailable:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = true
            NoNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = false
        }
    }
    
    
    // MARK: - Actions
    
}


// MARK: - Account Picker Delegate

extension NewOutageViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        //getOutageStatus()
    }
    
}


// MARK: - Text View Link Delegate

extension NewOutageViewController: DataDetectorTextViewLinkTapDelegate {
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        Analytics.log(event: .outageAuthEmergencyCall)
    }
}
