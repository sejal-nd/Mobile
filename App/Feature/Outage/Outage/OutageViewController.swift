//
//  OutageViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class OutageViewController: AccountPickerViewController {
    
    enum UserState {
        case authenticated
        case unauthenticated
    }
    
    enum State {
        case normal
        case loading
        case gasOnly
        case maintenance
        case noNetwork
        case unavailable
    }
    
    @IBOutlet weak var accountInfoBar: AccountInfoBar!
    @IBOutlet weak var mainContainerView: UIView!
    @IBOutlet weak var maintenanceModeContainerView: UIView!
    @IBOutlet weak var noNetworkConnectionContainerView: UIView!
    @IBOutlet weak var loadingContainerView: UIView!
    @IBOutlet weak var gasOnlyContainerView: UIView!
    @IBOutlet weak var notAvailableContainerView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var outageStatusView: OutageStatusView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
    
    private lazy var outageTrackerViewController: OutageTrackerViewController? = {
        let storyboard = UIStoryboard(name: "OutageTracker", bundle: Bundle.main)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "OutageTrackerViewController") as? OutageTrackerViewController {
            self.add(asChildViewController: vc)
            return vc
        }
        return nil
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(loadOutageStatus(sender:)), for: .valueChanged)
        refreshControl.tintColor = .deepGray
        refreshControl.backgroundColor = .softGray
        return refreshControl
    }()
    
    let viewModel = OutageViewModel()
    
    var userState: UserState = .authenticated
    
    var shortcutItem: ShortcutItem = .none
    
    var accountsLoaded = false
    
    let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAccountPicker()
        
        configureTableView()
        
        configureTableHeaderFooterView()
        
        viewModel.isUserAuthenticated = userState == .authenticated
        
        configureUserState(userState)
        
        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let shouldHideNavigationBar = userState == .authenticated ? true : false
        navigationController?.setNavigationBarHidden(shouldHideNavigationBar, animated: true)
        clearTimestampForReportedOutage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if userState == .authenticated {
            FirebaseUtility.logScreenView(.outageView(className: self.className))
        } else {
            FirebaseUtility.logScreenView(.unauthenticatedOutageView(className: self.className))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
        tableView.sizeFooterToFit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        shortcutItem = .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReportOutageViewController {
            if let outageStatus = viewModel.outageStatus {
                vc.viewModel.outageStatus = outageStatus
                vc.viewModel.phoneNumber.accept(outageStatus.contactHomeNumber ?? "")
                vc.viewModel.accountNumber = viewModel.accountNumber
                vc.delegate = self
            }
            vc.unauthenticatedExperience = userState == .unauthenticated ? true : false
        } else if let vc = segue.destination as? OutageMapViewController,
            let hasPressedStreetlightOutageMapButton = sender as? Bool, hasPressedStreetlightOutageMapButton {
            vc.hasPressedStreetlightOutageMapButton = hasPressedStreetlightOutageMapButton
        } else if segue.identifier == "noNetworkEmbed" {
            for subview in segue.destination.view.subviews {
                if let noNetworkView = subview as? NoNetworkConnectionView {
                    noNetworkView.reload.subscribe(onNext: { [weak self] _ in
                        
                        // Re-fetch feature flag values
                        FeatureFlagUtility.shared.fetchCloudValues()
                        
                        self?.configureState(.loading)
                        self?.loadOutageStatus()
                    }).disposed(by: disposeBag)
                }
            }
        } else if segue.identifier == "maintModeEmbed" {
            for subview in segue.destination.view.subviews {
                if let maintModeView = subview as? MaintenanceModeView {
                    maintModeView.reload.subscribe(onNext: { [weak self] _ in
                        self?.configureState(.loading)
                        self?.loadOutageStatus()
                    }).disposed(by: disposeBag)
                }
            }
        }
    }
    
    
    // MARK: - Helper
    
    private func add(asChildViewController vc: UIViewController) {
        addChild(vc)
        vc.view.frame = mainContainerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mainContainerView.addSubview(vc.view)
        vc.didMove(toParent: self)
    }
    
    private func remove(asChildViewController vc: UIViewController) {
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
    }
    
    private func updateView() {
        if Configuration.shared.opco == .bge {
            guard let outageTrackerVC = outageTrackerViewController else {
                return
            }
            add(asChildViewController: outageTrackerVC)
            mainContainerView.isHidden = false
        } else {
            mainContainerView.isHidden = true
        }
    }
    
    private func configureAccountPicker() {
        accountPicker.delegate = self
        accountPicker.parentViewController = self
    }
    
    private func configureTableView() {
        let titleDetailCell = UINib(nibName: TitleSubTitleRow.className, bundle: nil)
        tableView.register(titleDetailCell, forCellReuseIdentifier: TitleSubTitleRow.className)
        tableView.accessibilityLabel = "outageTableView"
        tableView.reloadData()
        
        FeatureFlagUtility.shared.loadingDoneCallback = { [weak self] in
            self?.viewModel.outageMapURLString = FeatureFlagUtility.shared.string(forKey: .outageMapURL)
            self?.viewModel.streetlightOutageMapURLString = FeatureFlagUtility.shared.string(forKey: .streetlightMapURL)
            self?.tableView.reloadData()
        }
    }
    
    private func clearTimestampForReportedOutage() {
        let accountnum = (userState == .authenticated) ? AccountsStore.shared.currentAccount.accountNumber : viewModel.accountNumber
        if let accountNumber = accountnum {
            let key = UserDefaultKeys.reportedOutageTime + "-" + accountNumber
            if let reportedDate = UserDefaults.standard.object(forKey: key) as? Date {
                let difference = Calendar.current.dateComponents([.second], from: reportedDate, to: Date()).second
                if difference >= 8 * 60 * 60 {
                    UserDefaults.standard.removeObject(forKey: key)
                    UserDefaults.standard.removeObject(forKey: accountNumber)
                    UserDefaults.standard.synchronize()
                    tableView.reloadData()
                }
            }
        }
    }
    
    private func configureTableHeaderFooterView() {
        // Header
        outageStatusView.delegate = self
        outageStatusView.isOutageStatusInactive = viewModel.isOutageStatusInactive
        
        // Footer
        footerTextView.font = SystemFont.regular.of(textStyle: .footnote)
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.linkTapDelegate = self
    }
    
    @objc
    private func loadOutageStatus(sender: UIRefreshControl? = nil) {
        viewModel.fetchData(onSuccess: { [weak self] outageStatus in
            
            self?.viewModel.isOutageStatusInactive = outageStatus.isInactive
            // Pull to Refresh
            if sender != nil {
                sender?.endRefreshing()
                self?.viewModel.hasJustReportedOutage = false
                FeatureFlagUtility.shared.fetchCloudValues()
            }
            else {
                self?.tableView.reloadData()
            }
            
            guard let `self` = self else { return }
            
            if outageStatus.isGasOnly {
                self.configureState(.gasOnly)
            } else {
                self.configureState(.normal)
                
                let currentAccount = AccountsStore.shared.currentAccount
                
                // Enable / Disable Report Outage Cell
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TitleSubTitleRow {
                    if outageStatus.isNoPay || outageStatus.isFinaled || outageStatus.isNonService || self.viewModel.isOutageStatusInactive || currentAccount.isFinaled || currentAccount.serviceType == nil {
                        cell.isEnabled = false
                    } else {
                        cell.isEnabled = true
                    }
                }

                self.outageStatusView.setOutageStatus(outageStatus,
                                                      reportedResults: self.viewModel.reportedOutage,
                                                      hasJustReported: self.viewModel.hasJustReportedOutage)
            }
            
            // If coming from shortcut, check these flags for report outage button availablility
            if !outageStatus.isGasOnly &&
                !outageStatus.isNoPay &&
                !outageStatus.isFinaled &&
                !outageStatus.isNonService &&
                self.shortcutItem == .reportOutage {
                self.performSegue(withIdentifier: "reportOutageSegue", sender: self)
            }
            self.shortcutItem = .none
            }, onError: { [weak self] error in
                self?.shortcutItem = .none
                if error == .noNetwork {
                    self?.configureState(.noNetwork)
                } else if error == .blockAccount {
                    self?.configureState(.unavailable)
                }
            }, onMaintenance: { [weak self] in
                self?.shortcutItem = .none
                self?.configureState(.maintenance)
        })
    }
    
    private func configureUserState(_ userState: UserState) {
        switch userState {
        case .authenticated:
            navigationController?.setNavigationBarHidden(true, animated: true)
            accountPicker.isHidden = false
            accountInfoBar.isHidden = true
            
            tableView.addSubview(refreshControl)
            
            configureState(.loading)
        case .unauthenticated:
            title = "Outage"
            
            navigationController?.setNavigationBarHidden(false, animated: true)
            accountPicker.isHidden = true
            shouldLoadAccounts = false
            accountInfoBar.isHidden = false
            
            guard let outageStatus = viewModel.outageStatus else { return }
            
            // Account Info Bar
            if let accountNumberText = outageStatus.maskedAccountNumber,
                let addressText = outageStatus.maskedAddress {
                accountInfoBar.configure(accountNumberText: accountNumberText, addressText: "\(addressText)...")
            }
            // Outage Status View
            configureUnauthenticatedOutageStatus(outageStatus)
        }
    }
    
    private func configureState(_ state: State) {
        switch state {
        case .normal:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = true
            noNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = true
        case .loading:
            loadingContainerView.isHidden = false
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = true
            noNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = true
        case .gasOnly:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = false
            maintenanceModeContainerView.isHidden = true
            noNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = true
        case .maintenance:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = false
            noNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = true
        case .noNetwork:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = true
            noNetworkConnectionContainerView.isHidden = false
            notAvailableContainerView.isHidden = true
        case .unavailable:
            loadingContainerView.isHidden = true
            gasOnlyContainerView.isHidden = true
            maintenanceModeContainerView.isHidden = true
            noNetworkConnectionContainerView.isHidden = true
            notAvailableContainerView.isHidden = false
        }
    }
    
    private func configureUnauthenticatedOutageStatus(_ outageStatus: OutageStatus) {
        self.configureState(.normal)
        
        // Enable / Disable Report Outage Cell
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TitleSubTitleRow {
            if outageStatus.isNoPay  || outageStatus.isFinaled || outageStatus.isNonService {
                cell.isEnabled = false
            } else {
                cell.isEnabled = true
            }
            
            cell.isEnabled = !outageStatus.isNoPay
        }
        
        self.outageStatusView.setOutageStatus(outageStatus,
                                              reportedResults: self.viewModel.reportedOutage,
                                              hasJustReported: self.viewModel.hasJustReportedOutage)
    }
}


// MARK: - Table View Data Source

extension OutageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleSubTitleRow.className, for: indexPath) as? TitleSubTitleRow else { fatalError("Invalid cell type.") }
        cell.backgroundColor = .softGray
        cell.hideSeparator = true
        
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            var detailText = (accountsLoaded && viewModel.reportedOutage != nil) ? viewModel.outageReportedDateString : nil
            let key = userState == .unauthenticated ? viewModel.accountNumber : AccountsStore.shared.currentAccount.accountNumber
            if detailText == nil,
                let reportedTime = UserDefaults.standard.object(forKey: key ?? AccountsStore.shared.currentAccount.accountNumber) as? String {
                detailText = reportedTime
            }
            cell.configure(image: UIImage(named: "ic_reportoutage"), title: "Report Outage", detail: detailText)
        case IndexPath(row: 1, section: 0):
            let title = Configuration.shared.opco.isPHI ? "Report Street Light Problem" : "Report Street Light Outage"
            cell.configure(image: #imageLiteral(resourceName: "ic_streetlightoutage"), title: title, detail: nil)
        case IndexPath(row: 2, section: 0):
            cell.configure(image: UIImage(named: "ic_mapoutage"), title: "View Outage Map", detail: nil)
        default:
            fatalError("Invalid index path.")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 1:
            // Streetlight Map
            if userState == .unauthenticated || viewModel.streetlightOutageMapURLString.isEmpty {
                return 0
            } else {
                return UITableView.automaticDimension
            }
        case 2:
            // Outage Map
            if viewModel.outageMapURLString.isEmpty {
                return 0
            } else {
                return UITableView.automaticDimension
            }
        default:
            return UITableView.automaticDimension
        }
    }
}


// MARK: - Table View Delegate

extension OutageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? TitleSubTitleRow, cell.isEnabled else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "reportOutageSegue", sender: self)
        case 1:
            GoogleAnalytics.log(event: .viewStreetlightMapOfferComplete)
            if userState == .authenticated {
                FirebaseUtility.logEvent(.authOutage(parameters: [.streetlight_map]))
            } else {
                FirebaseUtility.logEvent(.unauthOutage(parameters: [.streetlight_map]))
            }
            performSegue(withIdentifier: "outageMapSegue", sender: true)
        case 2:
            GoogleAnalytics.log(event: .viewMapOfferComplete)
            if userState == .authenticated {
                FirebaseUtility.logEvent(.authOutage(parameters: [.map]))
            } else {
                FirebaseUtility.logEvent(.unauthOutage(parameters: [.map]))
            }
            performSegue(withIdentifier: "outageMapSegue", sender: false)
        default:
            break
        }
    }
}


// MARK: - Account Picker Delegate

extension OutageViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        accountsLoaded = true
        viewModel.hasJustReportedOutage = false
        configureState(.loading)
        loadOutageStatus()
        clearTimestampForReportedOutage()
    }
}


// MARK: - Outage Status View Button Delegate

extension OutageViewController: OutageStatusDelegate {
    func didPressButton(button: UIButton, outageState: OutageState) {
        if userState == .authenticated {
            FirebaseUtility.logEvent(.authOutage(parameters: [.view_details]))
        } else {
            FirebaseUtility.logEvent(.unauthOutage(parameters: [.view_details]))
        }
        
        switch outageState {
        case .powerStatus(_), .reported, .unavailable, .inactive:
            guard let message = viewModel.outageStatus?.outageDescription else { return }
            let alertViewController = InfoAlertController(title: NSLocalizedString("Outage Status Details", comment: ""),
                                                          message: message)
            
            if let tabBarController = tabBarController {
                // Auth
                tabBarController.present(alertViewController, animated: true)
            } else {
                // Unauth
                navigationController?.present(alertViewController, animated: true)
            }
        case .nonPayment:
            tabBarController?.selectedIndex = 1
        }
    }
}


// MARK: - Text View Link Delegate

extension OutageViewController: DataDetectorTextViewLinkTapDelegate {
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        // Analytics
        GoogleAnalytics.log(event: .outageAuthEmergencyCall)
        if userState == .authenticated {
            FirebaseUtility.logEvent(.authOutage(parameters: [.emergency_number]))
        } else {
            FirebaseUtility.logEvent(.unauthOutage(parameters: [.emergency_number]))
        }
        viewModel.trackPhoneNumberAnalytics(isAuthenticated: userState == .authenticated, for: URL)
    }
}


// MARK: - Report Outage Delegate

extension OutageViewController: ReportOutageDelegate {
    func didReportOutage() {
        // Show Toast
        view.showToast(NSLocalizedString("Outage report received", comment: ""))
        
        // Update Report Outage Cell
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TitleSubTitleRow else { return }
        cell.updateSubTitle(viewModel.outageReportedDateString)
        
        // Enable Reported Outage State
        viewModel.hasJustReportedOutage = true
        guard let outageStatus = viewModel.outageStatus else { return }
        outageStatusView.setOutageStatus(outageStatus,
                                         reportedResults: viewModel.reportedOutage,
                                         hasJustReported: viewModel.hasJustReportedOutage)
        
        // Analytics
        let event: FirebaseEvent
        if userState == .authenticated {
            event = .authOutage(parameters: [.report_complete])
        } else {
            event = .unauthOutage(parameters: [.report_complete])
        }
        FirebaseUtility.logEvent(event)
    }
}
