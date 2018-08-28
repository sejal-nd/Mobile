//
//  OutageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import Lottie

class OutageViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var backgroundScrollConstraint: NSLayoutConstraint!
    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!
    @IBOutlet weak var maintenanceModeView: MaintenanceModeView!
    @IBOutlet weak var scrollViewContentView: UIView!
    @IBOutlet weak var accountContentView: UIView!
    @IBOutlet weak var gasOnlyView: UIView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingAnimationView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var outageStatusButton: OutageStatusButton!
    @IBOutlet weak var reportOutageButton: DisclosureButton!
    @IBOutlet weak var reportStreetlightOutageButton: DisclosureButton!
    @IBOutlet weak var viewOutageMapButton: DisclosureButton!
    @IBOutlet weak var gasOnlyTitleLabel: UILabel!
    @IBOutlet weak var gasOnlyTextView: DataDetectorTextView!
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    @IBOutlet weak var customErrorView: UIView!
    @IBOutlet weak var customErrorTitleLabel: UILabel!
    @IBOutlet weak var customErrorDetailLabel: UILabel!
    
    // We keep track of this constraint because AutoLayout uses it to calculate the height of the scrollView's content
    // When the gasOnlyView is hidden, we do not want it's height to impact the scrollView content size (the normal outage
    // view does not need to scroll on iPhone 7 size), so we use this to toggle active/inactive. Cannot be weak reference
    // because setting isActive = false would set to nil
    @IBOutlet var gasOnlyTextViewBottomSpaceConstraint: NSLayoutConstraint!
    
    var loadingLottieAnimation = LOTAnimationView(name: "outage_loading")
    var refreshControl: UIRefreshControl?
    
    var shortcutItem = ShortcutItem.none
    
    let viewModel = OutageViewModel(accountService: ServiceFactory.createAccountService(),
                                    outageService: ServiceFactory.createOutageService(),
                                    authService: ServiceFactory.createAuthenticationService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Outage", comment: "")
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        loadingLottieAnimation.frame = CGRect(x: 0, y: 0, width: loadingAnimationView.frame.size.width, height: loadingAnimationView.frame.size.height)
        loadingLottieAnimation.loopAnimation = true
        loadingLottieAnimation.contentMode = .scaleAspectFill
        loadingAnimationView.addSubview(loadingLottieAnimation)
        loadingLottieAnimation.play()
        
        outageStatusButton.delegate = self
        
        footerTextView.font = SystemFont.regular.of(textStyle: .headline)
        footerTextView.textContainerInset = .zero
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.text = viewModel.footerTextViewText
        footerTextView.linkTapDelegate = self
        
        gasOnlyTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        gasOnlyTextView.font = OpenSans.regular.of(textStyle: .subheadline)
        gasOnlyTextView.textContainerInset = .zero
        gasOnlyTextView.tintColor = .actionBlue
        gasOnlyTextView.text = viewModel.gasOnlyMessage
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        customErrorTitleLabel.textColor = .blackText
        customErrorTitleLabel.text = NSLocalizedString("Account Ineligible", comment: "")
        customErrorDetailLabel.textColor = .blackText
        customErrorDetailLabel.text = NSLocalizedString("This profile type does not have access to the mobile app. " +
            "Access your account on our responsive website.", comment: "")
        
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                self.accountContentView.isHidden = true
                self.gasOnlyTextViewBottomSpaceConstraint.isActive = false
                self.gasOnlyView.isHidden = true
                self.errorLabel.isHidden = true
                self.customErrorView.isHidden = true
                self.loadingView.isHidden = true
                self.noNetworkConnectionView.isHidden = true
                self.maintenanceModeView.isHidden = true
                self.setRefreshControlEnabled(enabled: false)
            case .readyToFetchData:
                if AccountsStore.shared.currentAccount != self.accountPicker.currentAccount {
                    self.getOutageStatus()
                } else if self.viewModel.currentOutageStatus == nil {
                    self.getOutageStatus()
                }
            }
        }).disposed(by: disposeBag)
        
        updateContent(outageJustReported: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(killRefresh), name: .didMaintenanceModeTurnOn, object: nil)
        
        RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.updateContent(outageJustReported: true) })
            .disposed(by: disposeBag)
        
        Observable.merge(noNetworkConnectionView.reload, maintenanceModeView.reload)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.getOutageStatus() })
            .disposed(by: disposeBag)
        
        
        scrollView?.rx.contentOffset.asDriver()
            .map { min(0, $0.y) }
            .distinctUntilChanged()
            .drive(backgroundScrollConstraint.rx.constant)
            .disposed(by: disposeBag)
        
        if Environment.shared.opco == .comEd {
            reportStreetlightOutageButton.isHidden = false
        } else {
            reportStreetlightOutageButton.isHidden = true
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.log(event: .outageStatusOfferComplete)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shortcutItem = .none
    }
    
    @objc func killRefresh() -> Void {
        refreshControl?.endRefreshing()
        scrollView!.alwaysBounceVertical = false
    }
    
    func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            scrollView!.insertSubview(refreshControl!, at: 0)
            scrollView!.alwaysBounceVertical = true
        } else {
            if let rc = refreshControl {
                rc.endRefreshing()
                rc.removeFromSuperview()
                refreshControl = nil
            }
            scrollView!.alwaysBounceVertical = false
        }
    }
    
    func updateContent(outageJustReported: Bool) {
        if let currentOutageStatus = viewModel.currentOutageStatus {
            layoutBigButtonContent(outageJustReported: outageJustReported)
            
            errorLabel.isHidden = true
            
            // Show/hide the top level container views
            if currentOutageStatus.flagGasOnly {
                gasOnlyTextViewBottomSpaceConstraint.isActive = true
                gasOnlyView.isHidden = false
                accountContentView.isHidden = true
            } else {
                gasOnlyTextViewBottomSpaceConstraint.isActive = false
                gasOnlyView.isHidden = true
                accountContentView.isHidden = false
            }
            
            // Update the Report Outage button
            if viewModel.reportedOutage != nil {
                reportOutageButton.setDetailLabel(text: viewModel.outageReportedDateString, checkHidden: false)
                reportOutageButton.accessibilityLabel = String.localizedStringWithFormat("Report outage. %@", viewModel.outageReportedDateString)
            } else {
                reportOutageButton.setDetailLabel(text: "", checkHidden: true)
                reportOutageButton.accessibilityLabel = NSLocalizedString("Report outage", comment: "")
            }
            
            reportOutageButton.isEnabled = !currentOutageStatus.flagNoPay && !currentOutageStatus.flagFinaled && !currentOutageStatus.flagNonService
        }
    }
    
    func layoutBigButtonContent(outageJustReported: Bool) {
        let currentOutageStatus = viewModel.currentOutageStatus!

        if outageJustReported && viewModel.reportedOutage != nil {
            outageStatusButton.setReportedState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else if currentOutageStatus.activeOutage {
            outageStatusButton.setOutageState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else if currentOutageStatus.flagFinaled || currentOutageStatus.flagNoPay || currentOutageStatus.flagNonService {
            outageStatusButton.setIneligibleState(flagFinaled: currentOutageStatus.flagFinaled, nonPayFinaledMessage: viewModel.accountNonPayFinaledMessage)
        } else { // Power is on
            outageStatusButton.setPowerOnState()
        }
    }
    
    func getOutageStatus() {
        accountContentView.isHidden = true
        gasOnlyTextViewBottomSpaceConstraint.isActive = false
        gasOnlyView.isHidden = true
        errorLabel.isHidden = true
        customErrorView.isHidden = true
        loadingView.isHidden = false
        scrollView?.isHidden = false
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        setRefreshControlEnabled(enabled: false)
        viewModel.fetchData(onSuccess: { [weak self] in
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            self?.scrollView?.isHidden = false
            self?.noNetworkConnectionView.isHidden = true
            self?.loadingView.isHidden = true
            self?.maintenanceModeView.isHidden = true
            self?.setRefreshControlEnabled(enabled: true)
            self?.updateContent(outageJustReported: false)
            
            // If coming from shortcut, check these flags for report outage button availablility
            if let outageStatus = self?.viewModel.currentOutageStatus,
                !outageStatus.flagGasOnly &&
                    !outageStatus.flagNoPay &&
                    !outageStatus.flagFinaled &&
                    !outageStatus.flagNonService &&
                    self?.shortcutItem == .reportOutage {
                self?.performSegue(withIdentifier: "reportOutageSegue", sender: self)
            }
            
            self?.shortcutItem = .none
            }, onError: { [weak self] serviceError in
                self?.shortcutItem = .none
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
                if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                    self?.scrollView?.isHidden = true
                    self?.noNetworkConnectionView.isHidden = false
                } else {
                    self?.scrollView?.isHidden = false
                    self?.noNetworkConnectionView.isHidden = true
                }
                self?.loadingView.isHidden = true
                self?.setRefreshControlEnabled(enabled: true)
                
                if serviceError.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue {
                    self?.errorLabel.isHidden = true
                    self?.customErrorView.isHidden = false
                } else {
                    self?.errorLabel.isHidden = false
                    self?.customErrorView.isHidden = true
                }
                self?.maintenanceModeView.isHidden = true
            }, onMaintenance: { [weak self] in
                self?.shortcutItem = .none
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
                self?.maintenanceModeView.isHidden = false
                self?.scrollView?.isHidden = true
                self?.noNetworkConnectionView.isHidden = true
                self?.loadingView.isHidden = true
                self?.setRefreshControlEnabled(enabled: true)
                self?.errorLabel.isHidden = true
                self?.customErrorView.isHidden = true
                
        })
    }
    
    // MARK: - Actions
    
    @objc func onPullToRefresh() {
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let `self` = self else { return }
            self.refreshControl?.endRefreshing()
            self.maintenanceModeView.isHidden = true
            self.updateContent(outageJustReported: false)
        }, onError: { [weak self] serviceError in
            guard let `self` = self else { return }
            self.refreshControl?.endRefreshing()
            
            if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                self.scrollView?.isHidden = true
                self.noNetworkConnectionView.isHidden = false
            } else {
                self.scrollView?.isHidden = false
                self.noNetworkConnectionView.isHidden = true
            }

            if serviceError.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue {
                self.errorLabel.isHidden = true
                self.customErrorView.isHidden = false
            } else {
                self.errorLabel.isHidden = false
                self.customErrorView.isHidden = true
            }
            
            // Hide everything else
            self.accountContentView.isHidden = true
            self.gasOnlyTextViewBottomSpaceConstraint.isActive = false
            self.gasOnlyView.isHidden = true
            self.maintenanceModeView.isHidden = true
            }, onMaintenance: { [weak self] in
                guard let `self` = self else { return }
                self.refreshControl?.endRefreshing()
                self.maintenanceModeView.isHidden = false
                self.scrollView?.isHidden = true
                self.noNetworkConnectionView.isHidden = true
                self.errorLabel.isHidden = true
                self.customErrorView.isHidden = true
                
                // Hide everything else
                self.accountContentView.isHidden = true
                self.gasOnlyTextViewBottomSpaceConstraint.isActive = false
                self.gasOnlyView.isHidden = true
        })
    }
    
    @IBAction func onReportOutagePress() {
        performSegue(withIdentifier: "reportOutageSegue", sender: self)
    }
    
    @IBAction func onViewStreetlightOutageMapPress() {
        viewModel.hasPressedStreetlightOutageMapButton = true
        Analytics.log(event: .viewStreetlightMapOfferComplete)
        performSegue(withIdentifier: "outageMapSegue", sender: self)
    }
    
    @IBAction func onViewOutageMapPress() {
        viewModel.hasPressedStreetlightOutageMapButton = false
        Analytics.log(event: .viewMapOfferComplete)
        performSegue(withIdentifier: "outageMapSegue", sender: self)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReportOutageViewController {
            vc.viewModel.outageStatus = viewModel.currentOutageStatus!
            if let phone = viewModel.currentOutageStatus!.contactHomeNumber {
                vc.viewModel.phoneNumber.value = phone
            }
            
            // Show a toast only after an outage is reported from this workflow
            RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
                .drive(onNext: { [weak self] in
                    guard let this = self else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                        this.view.showToast(NSLocalizedString("Outage report received", comment: ""))
                        Analytics.log(event: .reportOutageAuthComplete)
                    })
                })
                .disposed(by: vc.disposeBag)
        } else if let vc = segue.destination as? OutageMapViewController {
            vc.hasPressedStreetlightOutageMapButton = viewModel.hasPressedStreetlightOutageMapButton
        }
    }
    
}

extension OutageViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        getOutageStatus()
    }
    
}

extension OutageViewController: OutageStatusButtonDelegate {
    func outageStatusButtonWasTapped(_ outageStatusButton: OutageStatusButton) {
        Analytics.log(event: .outageStatusDetails)
        if viewModel.currentOutageStatus!.flagNoPay && Environment.shared.opco != .bge  {
            tabBarController?.selectedIndex = 1 // Jump to Bill tab
        } else {
            if let message = viewModel.currentOutageStatus!.outageDescription {
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension OutageViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        Analytics.log(event: .outageAuthEmergencyCall)
    }
}
