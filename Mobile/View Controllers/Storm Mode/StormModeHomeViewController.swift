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
    
    @IBOutlet weak var gradientView: UIView!
    var gradientLayer = CAGradientLayer()
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var exitView: UIView! {
        didSet {
            exitView.isHidden = true
        }
    }
    @IBOutlet weak var headerView: UIView!

    @IBOutlet weak var exitTextLabel: UILabel!
    @IBOutlet weak var exitButton: ButtonControl! {
        didSet {
            exitButton.layer.cornerRadius = 10.0
            exitButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 6)
        }
    }
    
    @IBOutlet weak var headerContentView: ButtonControl! {
        didSet {
            headerContentView.layer.cornerRadius = 10.0
            headerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 6)
        }
    }
    
    @IBOutlet weak var headerViewTitleLabel: UILabel! {
        didSet {
            headerViewTitleLabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    
    @IBOutlet weak var headerViewDescriptionLabel: UILabel! {
        didSet {
            headerViewDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet weak var footerTextView: DataDetectorTextView! {
        didSet {
            footerTextView.attributedText = viewModel.footerTextViewText
            footerTextView.textContainerInset = .zero
            footerTextView.textColor = .softGray
            footerTextView.tintColor = .white // For phone numbers
            footerTextView.linkTapDelegate = self
        }
    }
    
    @IBOutlet weak var gasOnlyView: UIView!
    @IBOutlet weak var gasOnlyTitleLabel: UILabel! {
        didSet {
            gasOnlyTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    @IBOutlet weak var gasOnlyTextView: DataDetectorTextView! {
        didSet {
            gasOnlyTextView.font = OpenSans.regular.of(textStyle: .subheadline)
            gasOnlyTextView.textContainerInset = .zero
            gasOnlyTextView.tintColor = .white
            gasOnlyTextView.text = viewModel.gasOnlyMessage
        }
    }
    
    @IBOutlet weak var finalPayView: UIView!
    @IBOutlet weak var finalPayTitleLabel: UILabel! {
        didSet {
            finalPayTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    @IBOutlet weak var finalPayTextView: DataDetectorTextView! {
        didSet {
            finalPayTextView.font = OpenSans.regular.of(textStyle: .subheadline)
            finalPayTextView.textContainerInset = .zero
            finalPayTextView.tintColor = .white
        }
    }
    @IBOutlet weak var finalPayButton: ButtonControl! {
        didSet {
            finalPayButton.layer.cornerRadius = 10.0
        }
    }
    @IBOutlet weak var finalPayButtonLabel: UILabel! {
        didSet {
            finalPayButtonLabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    
    /// This houses both the outage status button and the loading view for the button
    @IBOutlet weak var loadingContentView: UIView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingBackgroundView: UIView!
    @IBOutlet weak var loadingAnimationView: UIView!
    @IBOutlet weak var outageStatusButton: OutageStatusButton!
    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView! {
        didSet {
            noNetworkConnectionView.configureContactText(attributedText: viewModel.footerTextViewText)
        }
    }
    
    private var loadingLottieAnimation = LOTAnimationView(name: "sm_outage_loading")
    private var refreshControl: UIRefreshControl?
    
    let viewModel = StormModeHomeViewModel(authService: ServiceFactory.createAuthenticationService(),
                                                   outageService: ServiceFactory.createOutageService())
    
    let disposeBag = DisposeBag()
    var stormModePollingDisposable: Disposable?
    
    /// Controls if content is shown within cells
    var shouldShowOutageCellData = false {
        didSet {
            tableView.reloadSections([0], with: .none)
        }
    }
    
    // Controls if buttons / space are visible
    var shouldShowOutageCell = true {
        didSet {
            tableView.reloadSections([0], with: .none)
        }
    } 
    
    var stormModeEnded = false

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.primaryColor.cgColor,
            UIColor.primaryColor.withAlphaComponent(0).cgColor
        ]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)

        tableView.register(UINib(nibName: TitleTableViewHeaderView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: TitleTableViewHeaderView.className)
        tableView.register(UINib(nibName: TitleTableViewCell.className, bundle: nil), forCellReuseIdentifier: TitleTableViewCell.className)
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        outageStatusButton.delegate = self
        
        loadingLottieAnimation.frame = CGRect(x: 0, y: 0, width: loadingAnimationView.frame.size.width, height: loadingAnimationView.frame.size.height)
        loadingLottieAnimation.loopAnimation = true
        loadingLottieAnimation.contentMode = .scaleAspectFill
        loadingAnimationView.addSubview(loadingLottieAnimation)
        loadingLottieAnimation.play()
        

        // Events
        
        RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.updateContent(outageJustReported: true) })
            .disposed(by: disposeBag)
        
        Observable.merge(noNetworkConnectionView.reload)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.getOutageStatus() })
            .disposed(by: disposeBag)
        
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                self.outageStatusButton.isHidden = true
                self.gasOnlyView.isHidden = true
                self.finalPayView.isHidden = true
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start polling when the home screen appears, only if storm mode hasn't ended yet
        stormModePollingDisposable?.dispose()
        if !stormModeEnded {
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
        
        // Self Sizes Table View Header
        headerView.frame.size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        tableView.tableHeaderView = headerView
        
        loadingBackgroundView.layer.cornerRadius = loadingBackgroundView.frame.height / 2
    }
    
    
    // MARK: - Actions
    
    @IBAction func showStormModeDetails(_ sender: Any) {
        performSegue(withIdentifier: "UpdatesDetailSegue", sender: nil)
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
        stormModeEnded = true
        
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
            shouldShowOutageCellData = false
            outageStatusButton.isHidden = true
            noNetworkConnectionView.isHidden = true
            gasOnlyView.isHidden = true
            finalPayView.isHidden = true
            loadingView.isHidden = false
            scrollView?.isHidden = false
            setRefreshControlEnabled(enabled: false)
        }
        
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let `self` = self else { return }
            
            if didPullToRefresh {
                self.refreshControl?.endRefreshing()
            }

            UIAccessibility.post(notification: .screenChanged, argument: nil)
            self.shouldShowOutageCellData = true
            self.noNetworkConnectionView.isHidden = true
            self.scrollView?.isHidden = false
            self.loadingView.isHidden = true
            self.setRefreshControlEnabled(enabled: true)
            self.updateContent(outageJustReported: false)
            }, onError: { [weak self] serviceError in
                guard let `self` = self else { return }
                
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
            footerTextView.isHidden = true
            loadingContentView.isHidden = true
            outageStatusButton.isHidden = true
            shouldShowOutageCellData = false
            shouldShowOutageCell = false
        } else {
            gasOnlyView.isHidden = true
            footerTextView.isHidden = false
            shouldShowOutageCellData = true
            shouldShowOutageCell = true
            
            self.loadingContentView.isHidden = false
            outageStatusButton.onLottieAnimation?.animationProgress = 0.0
            outageStatusButton.onLottieAnimation?.play()
            
            outageStatusButton.isHidden = false
        }
        
        layoutBigButtonContent(outageJustReported: outageJustReported)
    }
    
    private func layoutBigButtonContent(outageJustReported: Bool) {
        let currentOutageStatus = viewModel.currentOutageStatus!
        
        if outageJustReported && viewModel.reportedOutage != nil {
            outageStatusButton.setReportedState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else if currentOutageStatus.activeOutage {
            outageStatusButton.setOutageState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else if currentOutageStatus.flagFinaled || currentOutageStatus.flagNoPay || currentOutageStatus.flagNonService {
            loadingContentView.isHidden = true
            outageStatusButton.isHidden = true
            finalPayView.isHidden = false
            finalPayTextView.text = viewModel.accountNonPayFinaledMessage
            
            finalPayButton.isHidden = currentOutageStatus.flagFinaled ? true : false
        } else { // Power is on
            outageStatusButton.setPowerOnState()
        }
    }
    
    private func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            refreshControl = UIRefreshControl()
            refreshControl?.tintColor = .white
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
    
    @objc private func killRefresh() -> Void {
        refreshControl?.endRefreshing()
        scrollView!.alwaysBounceVertical = false
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UpdatesDetailViewController {
            vc.opcoUpdate = OpcoUpdate(title: NSLocalizedString("Storm Mode is in effect", comment: ""), message: NSLocalizedString("Due to severe weather, limited features are available to allow us to better serve you.", comment: ""))
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
    
}

extension StormModeHomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == 0 else { return 60 }
        return shouldShowOutageCell ? 60 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.className) as? TitleTableViewCell else { return UITableViewCell() }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                // Must nil check AccountStore, it CAN be nil.  should be an optional AccountStore.shared.currentAccount
                
                if shouldShowOutageCellData {
                    // Populate Content
                    if viewModel.reportedOutage != nil, AccountsStore.shared.currentAccount != nil {
                        // Reported State
                        cell.configure(image: #imageLiteral(resourceName: "ic_check_outage_white"), text: NSLocalizedString("Report Outage", comment: ""), detailText: viewModel.outageReportedDateString, backgroundColor: .clear, shouldConstrainWidth: true)
                    } else {
                        // Regular State
                        cell.configure(image: #imageLiteral(resourceName: "ic_reportoutage"), text: NSLocalizedString("Report Outage", comment: ""), backgroundColor: .clear, shouldConstrainWidth: true)
                    }
                } else {
                    // Hide Content
                    cell.configure(image: nil, text: nil, detailText: nil, backgroundColor: .clear, shouldConstrainWidth: true, shouldHideDisclosure: true, shouldHideSeparator: true)
                }
            case 1:
                if shouldShowOutageCellData {
                    // Populate Content
                    cell.configure(image: #imageLiteral(resourceName: "ic_mapoutage"), text: NSLocalizedString("View Outage Map", comment: ""), backgroundColor: .clear, shouldConstrainWidth: true)
                } else {
                    // Hide Content
                    cell.configure(image: nil, text: nil, detailText: nil, backgroundColor: .clear, shouldConstrainWidth: true, shouldHideDisclosure: true, shouldHideSeparator: true)
                }
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_nav_bill_white"), text: NSLocalizedString("Bill", comment: ""), backgroundColor: .clear, shouldConstrainWidth: true)
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_nav_more_white"), text: NSLocalizedString("More", comment: ""), backgroundColor: .clear, shouldConstrainWidth: true)
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "ReportOutageSegue", sender: nil)
            case 1:
                performSegue(withIdentifier: "OutageMapSegue", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "BillSegue", sender: nil)
            case 1:
                performSegue(withIdentifier: "MoreSegue", sender: nil)
            default:
                break
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0.5 // Only show the separator
        default:
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TitleTableViewHeaderView.className) as? TitleTableViewHeaderView else { return nil }
        
        switch section {
        case 0:
            if shouldShowOutageCellData {
                // Show Separator
                headerView.configure(text: nil, backgroundColor: .clear, shouldConstrainWidth: true, shouldHideSeparator: false)
            } else {
                // Hide Separator
                headerView.configure(text: nil, backgroundColor: .clear, shouldConstrainWidth: true, shouldHideSeparator: true)
            }
        case 1:
            headerView.configure(text: NSLocalizedString("More Options", comment: ""), backgroundColor: .clear, shouldConstrainWidth: true)
        default:
            break
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 21
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
