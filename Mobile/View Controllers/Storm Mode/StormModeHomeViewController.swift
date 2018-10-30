//
//  StormModeHomeViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 8/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import Lottie

class StormModeHomeViewController: AccountPickerViewController {
    
    override var showMinimizedPicker: Bool {
        return false
    }
    
    @IBOutlet private weak var gradientView: UIView!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet private weak var exitView: UIView! {
        didSet {
            exitView.isHidden = true
        }
    }

    @IBOutlet private weak var exitTextLabel: UILabel!
    @IBOutlet private weak var exitButton: ButtonControl! {
        didSet {
            exitButton.layer.cornerRadius = 10.0
            exitButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            exitButton.backgroundColorOnPress = .softGray
            exitButton.accessibilityLabel = NSLocalizedString("Exit storm mode", comment: "")
        }
    }
    
    @IBOutlet private weak var headerContentView: ButtonControl! {
        didSet {
            headerContentView.layer.cornerRadius = 10.0
            headerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            headerContentView.accessibilityLabel = NSLocalizedString("Storm mode is in effect. Due to severe weather, the most relevant features are optimized to allow us to beter serve you.", comment: "")
        }
    }
    
    @IBOutlet private weak var headerViewTitleLabel: UILabel! {
        didSet {
            headerViewTitleLabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    
    @IBOutlet private weak var headerViewDescriptionLabel: UILabel! {
        didSet {
            headerViewDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet private weak var headerCaretImageView: UIImageView!
    
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var footerLabel: UILabel! {
        didSet {
            footerLabel.text = viewModel.footerLabelText
        }
    }
    
    @IBOutlet private weak var footerPhoneButton: ButtonControl! {
        didSet {
            footerPhoneButton.roundCorners(.allCorners, radius: 4)
            footerPhoneButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            footerPhoneButton.accessibilityLabel = viewModel.footerPhoneLabelText
        }
    }
    
    @IBOutlet private weak var footerPhoneLabel: UILabel! {
        didSet {
            footerPhoneLabel.text = viewModel.footerPhoneLabelText
        }
    }
    
    @IBOutlet private weak var gasOnlyView: UIView!
    @IBOutlet private weak var gasOnlyTitleLabel: UILabel! {
        didSet {
            gasOnlyTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    @IBOutlet private weak var gasOnlyDetailLabel: UILabel! {
        didSet {
            gasOnlyDetailLabel.font = OpenSans.regular.of(textStyle: .subheadline)
            gasOnlyDetailLabel.text = viewModel.gasOnlyMessage
        }
    }
    
    @IBOutlet private weak var gasOnlyPhoneButton: ButtonControl! {
        didSet {
            gasOnlyPhoneButton.roundCorners(.allCorners, radius: 4)
            gasOnlyPhoneButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            gasOnlyPhoneButton.isHidden = Environment.shared.opco == .comEd
            gasOnlyPhoneButton.accessibilityLabel = viewModel.footerPhoneLabelText
        }
    }
    
    @IBOutlet private weak var gasOnlyPhoneLabel: UILabel! {
        didSet {
            gasOnlyPhoneLabel.text = viewModel.footerPhoneLabelText
        }
    }
    
    @IBOutlet private weak var finalPayView: UIView!
    @IBOutlet private weak var finalPayTitleLabel: UILabel! {
        didSet {
            finalPayTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    @IBOutlet private weak var finalPayTextView: DataDetectorTextView! {
        didSet {
            finalPayTextView.font = OpenSans.regular.of(textStyle: .subheadline)
            finalPayTextView.textContainerInset = .zero
            finalPayTextView.textContainer.lineFragmentPadding = 0
            finalPayTextView.tintColor = .white
        }
    }
    
    @IBOutlet private weak var finalPayButtonContainer: UIView!
    @IBOutlet private weak var finalPayButton: ButtonControl! {
        didSet {
            finalPayButton.layer.cornerRadius = 10.0
            finalPayButton.accessibilityLabel = NSLocalizedString("Pay bill", comment: "")
            finalPayButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    
    @IBOutlet private weak var finalPayButtonLabel: UILabel! {
        didSet {
            finalPayButtonLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    /// This houses both the outage status button and the loading view for the button
    @IBOutlet private weak var loadingContentView: UIView!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var loadingBackgroundView: UIView!
    @IBOutlet private weak var loadingAnimationView: UIView!
    @IBOutlet private weak var outageStatusButton: OutageStatusButton!
    @IBOutlet private weak var noNetworkConnectionView: NoNetworkConnectionView! {
        didSet {
            noNetworkConnectionView.configureContactText(attributedText: viewModel.noNetworkAttributedText)
        }
    }
    
    @IBOutlet private weak var outageSectionContainer: UIView!
    @IBOutlet private weak var outageSectionStack: UIStackView!
    @IBOutlet private weak var reportOutageButton: DisclosureCellButton!
    @IBOutlet private weak var outageMapButton: DisclosureCellButton! {
        didSet {
            outageMapButton.configure(image: #imageLiteral(resourceName: "ic_mapoutage"), text: NSLocalizedString("View Outage Map", comment: ""))
        }
    }
    
    @IBOutlet private weak var moreOptionsLabel: UILabel! {
        didSet {
            moreOptionsLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    @IBOutlet private weak var billButton: DisclosureCellButton! {
        didSet {
            billButton.configure(image: #imageLiteral(resourceName: "ic_nav_bill_white"), text: NSLocalizedString("Bill", comment: ""))
        }
    }
    
    @IBOutlet private weak var moreButton: DisclosureCellButton! {
        didSet {
            moreButton.configure(image: #imageLiteral(resourceName: "ic_nav_more_white"), text: NSLocalizedString("More", comment: ""))
        }
    }
    
    private var loadingLottieAnimation = LOTAnimationView(name: "sm_outage_loading")
    private var refreshControl: UIRefreshControl?
    
    let viewModel = StormModeHomeViewModel(authService: ServiceFactory.createAuthenticationService(),
                                           outageService: ServiceFactory.createOutageService(),
                                           alertsService: ServiceFactory.createAlertsService())
    
    let disposeBag = DisposeBag()
    var stormModePollingDisposable: Disposable?

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .stormModeBlack
        
        let gradientColor: UIColor
        switch Environment.shared.opco {
        case .bge:
            gradientColor = .bgeGreen
        case .comEd, .peco:
            gradientColor = .primaryColor
        }
        
        gradientLayer.colors = [
            gradientColor.cgColor,
            gradientColor.withAlphaComponent(0).cgColor
        ]
        
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        outageStatusButton.delegate = self
        
        loadingLottieAnimation.frame = CGRect(x: 0, y: 0, width: loadingAnimationView.frame.size.width, height: loadingAnimationView.frame.size.height)
        loadingLottieAnimation.loopAnimation = true
        loadingLottieAnimation.contentMode = .scaleAspectFill
        loadingAnimationView.addSubview(loadingLottieAnimation)
        loadingLottieAnimation.play()
        
        viewModel.getStormModeUpdate()
        
        // Events
        
        RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.updateContent(outageJustReported: true) })
            .disposed(by: disposeBag)
        
        Observable.merge(noNetworkConnectionView.reload)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.getOutageStatus() })
            .disposed(by: disposeBag)
        
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let self = self else { return }
            switch(state) {
            case .loadingAccounts:
                self.outageStatusButton.isHidden = true
                self.gasOnlyView.isHidden = true
                self.finalPayView.isHidden = true
                self.footerView.isHidden = true
                self.noNetworkConnectionView.isHidden = true
                self.setRefreshControlEnabled(enabled: false)
            case .readyToFetchData:
                if AccountsStore.shared.currentAccount != self.accountPicker.currentAccount {
                    self.getOutageStatus()
                } else if self.viewModel.currentOutageStatus == nil {
                    self.getOutageStatus()
                }
            }
        }).disposed(by: disposeBag)
        
        viewModel.stormModeUpdate.asDriver().isNil().drive(headerCaretImageView.rx.isHidden).disposed(by: disposeBag)
        
        Driver.merge(reportOutageButton.rx.touchUpInside.asDriver().map(to: "ReportOutageSegue"),
                     outageMapButton.rx.touchUpInside.asDriver().map(to: "OutageMapSegue"),
                     billButton.rx.touchUpInside.asDriver().map(to: "BillSegue"),
                     moreButton.rx.touchUpInside.asDriver().map(to: "MoreSegue"))
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: $0, sender: nil)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start polling when the home screen appears, only if storm mode hasn't ended yet
        stormModePollingDisposable?.dispose()
        if !viewModel.stormModeEnded {
            stormModePollingDisposable = viewModel.startStormModePolling()
                .drive(onNext: { [weak self] in self?.stormModeDidEnd() })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop polling when the home screen is left
        stormModePollingDisposable?.dispose()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = gradientView.bounds
        loadingBackgroundView.layer.cornerRadius = loadingBackgroundView.frame.height / 2
    }
    
    
    // MARK: - Actions
    
    @IBAction func showStormModeDetails(_ sender: Any) {
        if viewModel.stormModeUpdate.value != nil {
            performSegue(withIdentifier: "UpdatesDetailSegue", sender: nil)
        }
    }

    @IBAction func exitStormMode(_ sender: Any) {
        returnToMainApp()
    }
    
    @objc private func onPullToRefresh() {
        getOutageStatus(didPullToRefresh: true)
    }
    
    @IBAction func payButtonPress(_ sender: Any) {
        performSegue(withIdentifier: "BillSegue", sender: nil)
    }
    
    // MARK: - Helper
    
    private func stormModeDidEnd() {
        let yesAction = UIAlertAction(title: NSLocalizedString("Exit Storm Mode", comment: ""), style: .default)
        { [weak self] _ in
            self?.returnToMainApp()
        }
        
        let noAction = UIAlertAction(title: NSLocalizedString("No, Thanks", comment: ""), style: .cancel)
        { [weak self] _ in
            self?.exitView.isHidden = false
            self?.headerContentView.isHidden = true
        }
        
        presentAlert(title: NSLocalizedString("Exit Storm Mode", comment: ""),
                     message: NSLocalizedString("All features are now available. Would you like to exit storm mode? You can also do this from the home screen.", comment: ""),
                     style: .alert,
                     actions: [yesAction, noAction])
    }
    
    private func getOutageStatus(didPullToRefresh: Bool = false) {
        if !didPullToRefresh {
            loadingContentView.isHidden = false
            outageSectionStack.isHidden = true
            outageStatusButton.isHidden = true
            footerView.isHidden = true
            noNetworkConnectionView.isHidden = true
            gasOnlyView.isHidden = true
            finalPayView.isHidden = true
            loadingView.isHidden = false
            scrollView?.isHidden = false
            setRefreshControlEnabled(enabled: false)
        }
        
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let self = self else { return }
            
            if didPullToRefresh {
                self.refreshControl?.endRefreshing()
            }

            UIAccessibility.post(notification: .screenChanged, argument: nil)
            self.outageSectionContainer.isHidden = false
            self.outageSectionStack.isHidden = false
            self.noNetworkConnectionView.isHidden = true
            self.scrollView?.isHidden = false
            self.loadingView.isHidden = true
            self.finalPayTitleLabel.isHidden = false
            self.setRefreshControlEnabled(enabled: true)
            self.updateContent(outageJustReported: false)
            }, onError: { [weak self] serviceError in
                guard let self = self else { return }
                
                if didPullToRefresh {
                    self.refreshControl?.endRefreshing()
                }
                
                UIAccessibility.post(notification: .screenChanged, argument: nil)
                if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                    self.scrollView?.isHidden = true
                    self.noNetworkConnectionView.isHidden = false
                } else {
                    self.scrollView?.isHidden = false
                    self.noNetworkConnectionView.isHidden = true
                }
                
                self.loadingContentView.isHidden = true
                self.finalPayView.isHidden = false
                self.finalPayTitleLabel.isHidden = true
                self.finalPayTextView.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
                self.finalPayButtonContainer.isHidden = true
                self.outageSectionContainer.isHidden = true
                self.footerView.isHidden = false
                self.loadingView.isHidden = true
                self.setRefreshControlEnabled(enabled: true)
            })
    }
    
    private func returnToMainApp() {
        guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else { return }
        StormModeStatus.shared.isOn = false
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()
    }
    
    private func updateContent(outageJustReported: Bool) {
        guard let currentOutageStatus = viewModel.currentOutageStatus  else { return }

        // Show/hide the top level container views
        if currentOutageStatus.flagGasOnly {
            gasOnlyView.isHidden = false
            footerView.isHidden = true
            loadingContentView.isHidden = true
            outageStatusButton.isHidden = true
            outageSectionContainer.isHidden = true
            outageSectionStack.isHidden = true
        } else {
            gasOnlyView.isHidden = true
            footerView.isHidden = false
            outageSectionContainer.isHidden = false
            outageSectionStack.isHidden = false
            loadingContentView.isHidden = false
            outageStatusButton.onLottieAnimation?.animationProgress = 0.0
            outageStatusButton.onLottieAnimation?.play()
            
            outageStatusButton.isHidden = false
        }
        
        if viewModel.reportedOutage != nil {
            // Reported State
            reportOutageButton.configure(image: #imageLiteral(resourceName: "ic_check_outage_white"), text: NSLocalizedString("Report Outage", comment: ""), detailText: viewModel.outageReportedDateString)
        } else {
            // Regular State
            reportOutageButton.configure(image: #imageLiteral(resourceName: "ic_reportoutage"), text: NSLocalizedString("Report Outage", comment: ""), enabled: viewModel.reportOutageEnabled)
        }
        
        layoutBigButtonContent(outageJustReported: outageJustReported)
    }
    
    private func layoutBigButtonContent(outageJustReported: Bool) {
        let currentOutageStatus = viewModel.currentOutageStatus!
        
        if outageJustReported && viewModel.reportedOutage != nil {
            outageStatusButton.setReportedState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else if currentOutageStatus.flagFinaled || currentOutageStatus.flagNoPay || currentOutageStatus.flagNonService {
            loadingContentView.isHidden = true
            outageStatusButton.isHidden = true
            finalPayView.isHidden = false
            finalPayTextView.text = viewModel.accountNonPayFinaledMessage
            finalPayButtonContainer.isHidden = !currentOutageStatus.flagNoPay
        } else if currentOutageStatus.activeOutage {
            outageStatusButton.setOutageState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else { // Power is on
            outageStatusButton.setPowerOnState()
        }
    }
    
    private func setRefreshControlEnabled(enabled: Bool) {
        if let rc = refreshControl {
            rc.endRefreshing()
            rc.removeFromSuperview()
            refreshControl = nil
        }
        
        if enabled {
            refreshControl = UIRefreshControl()
            refreshControl?.tintColor = .white
            refreshControl!.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            scrollView!.insertSubview(refreshControl!, at: 0)
            scrollView!.alwaysBounceVertical = true
        } else {
            scrollView!.alwaysBounceVertical = false
        }
    }
    
    @objc private func killRefresh() -> Void {
        refreshControl?.endRefreshing()
        scrollView!.alwaysBounceVertical = false
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UpdatesDetailViewController {
            if let stormUpdate = viewModel.stormModeUpdate.value {
                vc.opcoUpdate = stormUpdate
            }
        } else if let vc = segue.destination as? ReportOutageViewController {
            navigationController?.setNavigationBarHidden(false, animated: false) // may be able to refactor this out into the root of prep for segue
            vc.viewModel.outageStatus = viewModel.currentOutageStatus!
            
            guard let phone = viewModel.currentOutageStatus!.contactHomeNumber else { return }
            vc.viewModel.phoneNumber.value = phone
        } else if let vc = segue.destination as? OutageMapViewController {
            navigationController?.setNavigationBarHidden(false, animated: false)
            vc.hasPressedStreetlightOutageMapButton = false
        } else if let vc = segue.destination as? MoreViewController {
            vc.shouldHideNavigationBar = false
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func onPhoneNumberPress(_ sender: ButtonControl) {
        var phoneStr: String?

        phoneStr = viewModel.footerPhoneLabelText
        
        if let phone = phoneStr, let url = URL(string: "telprompt://\(phone)"), UIApplication.shared.canOpenURL(url) {
            Analytics.log(event: .outageAuthEmergencyCall)
            UIApplication.shared.open(url)
        }
    }
    
}

// MARK: - Delegate Actions

extension StormModeHomeViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        getOutageStatus()
    }
    
}

extension StormModeHomeViewController: OutageStatusButtonDelegate {
    
    func outageStatusButtonWasTapped(_ outageStatusButton: OutageStatusButton) {
        Analytics.log(event: .outageStatusDetails)
        
        if let message = viewModel.currentOutageStatus!.outageDescription {
            presentAlert(title: nil, message: message, style: .alert, actions: [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)])
        }
    }
    
}

extension StormModeHomeViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        Analytics.log(event: .outageAuthEmergencyCall)
    }
    
}
