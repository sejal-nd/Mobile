//
//  NewOutageViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

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
    
    @IBOutlet weak var accountInfoBar: AccountInfoBarNew!
    @IBOutlet weak var maintenanceModeContainerView: UIView!
    @IBOutlet weak var NoNetworkConnectionContainerView: UIView!
    @IBOutlet weak var loadingContainerView: UIView!
    @IBOutlet weak var gasOnlyContainerView: UIView!
    @IBOutlet weak var notAvailableContainerView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var outageStatusView: OutageStatusView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(loadOutageStatus(sender:)), for: .valueChanged)
        refreshControl.tintColor = .primaryColor
        refreshControl.backgroundColor = .softGray
        return refreshControl
    }()
    
    let viewModel = OutageViewModel(accountService: ServiceFactory.createAccountService(),
                                            outageService: ServiceFactory.createOutageService(),
                                            authService: ServiceFactory.createAuthenticationService())
    
    var userState: UserState = .authenticated
    
    var shortcutItem: ShortcutItem = .none
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureAccountPicker()
        
        configureTableView()
        
        configureTableHeaderFooterView()
        
        configureUserState(userState)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let shouldHideNavigationBar = userState == .authenticated ? true : false
        navigationController?.setNavigationBarHidden(shouldHideNavigationBar, animated: true)
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
                vc.delegate = self
            }
            vc.unauthenticatedExperience = userState == .unauthenticated ? true : false
        } else if let vc = segue.destination as? OutageMapViewController, let hasPressedStreetlightOutageMapButton = sender as? Bool {
            vc.hasPressedStreetlightOutageMapButton = hasPressedStreetlightOutageMapButton
        }
    }
    
    
    // MARK: - Helper
    
    private func configureAccountPicker() {
        accountPicker.delegate = self
        accountPicker.parentViewController = self
    }
    
    private func configureTableView() {
        let titleDetailCell = UINib(nibName: TitleSubTitleRow.className, bundle: nil)
        tableView.register(titleDetailCell, forCellReuseIdentifier: TitleSubTitleRow.className)
        tableView.reloadData()
    }
    
    private func configureTableHeaderFooterView() {
        // Header
        outageStatusView.delegate = self

        // Footer
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.linkTapDelegate = self
    }
    
    @objc
    private func loadOutageStatus(sender: UIRefreshControl? = nil) {
        viewModel.fetchData(onSuccess: { [weak self] outageStatus in
            
            sender?.endRefreshing()
            
            guard let `self` = self else { return }
            if outageStatus.flagGasOnly {
                self.configureState(.gasOnly)
            } else {
                self.configureState(.normal)
                
                // Enable / Disable Report Outage Cell
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TitleSubTitleRow {
                    if outageStatus.flagNoPay  || outageStatus.flagFinaled || outageStatus.flagNonService {
                        cell.isEnabled = false
                    } else {
                        cell.isEnabled = true
                    }
                    
                    cell.isEnabled = !outageStatus.flagNoPay
                }
                
                self.outageStatusView.setOutageStatus(outageStatus,
                                                      reportedResults: self.viewModel.reportedOutage,
                                                      hasJustReported: self.viewModel.hasJustReportedOutage)
            }
            
            // If coming from shortcut, check these flags for report outage button availablility
            if !outageStatus.flagGasOnly &&
                    !outageStatus.flagNoPay &&
                    !outageStatus.flagFinaled &&
                    !outageStatus.flagNonService &&
                self.shortcutItem == .reportOutage {
                self.performSegue(withIdentifier: "reportOutageSegue", sender: self)
            }
            self.shortcutItem = .none
            }, onError: { [weak self] serviceError in
                self?.shortcutItem = .none
                if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                    self?.configureState(.noNetwork)
                } else if serviceError.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue {
                    
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
            
            loadOutageStatus()
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
                accountInfoBar.configure(accountNumberText: accountNumberText, addressText: addressText)
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
    
    private func configureUnauthenticatedOutageStatus(_ outageStatus: OutageStatus) {
        self.configureState(.normal)
        
        // Enable / Disable Report Outage Cell
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TitleSubTitleRow {
            if outageStatus.flagNoPay  || outageStatus.flagFinaled || outageStatus.flagNonService {
                cell.isEnabled = false
            } else {
                cell.isEnabled = true
            }
            
            cell.isEnabled = !outageStatus.flagNoPay
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
        
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            let detailText = viewModel.reportedOutage != nil ? viewModel.outageReportedDateString : nil
            cell.configure(image: UIImage(named: "ic_reportoutage"), title: "Report Outage", detail: detailText)
        case IndexPath(row: 1, section: 0):
            cell.configure(image: UIImage(named: "ic_streetlightoutage"), title: "Report Streetlight Outage", detail: nil)
        case IndexPath(row: 2, section: 0):
            cell.configure(image: UIImage(named: "ic_mapoutage"), title: "View Outage Map", detail: nil)
        default:
            fatalError("Invalid index path.")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row == 1 else { return UITableView.automaticDimension }
        return Environment.shared.opco == .comEd ? UITableView.automaticDimension : 0
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
            performSegue(withIdentifier: "outageMapSegue", sender: true)
        case 2:
            GoogleAnalytics.log(event: .viewMapOfferComplete)
            performSegue(withIdentifier: "outageMapSegue", sender: false)
        default:
            break
        }
    }
}


// MARK: - Account Picker Delegate

extension OutageViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        configureState(.loading)
        loadOutageStatus()
    }
}


// MARK: - Outage Status View Button Delegate

extension OutageViewController: OutageStatusDelegate {
    func didPressButton(button: UIButton, outageState: OutageState) {
        switch outageState {
        case .powerStatus(_), .reported, .unavailable:
            guard let message = viewModel.outageStatus?.outageDescription else { return }
            let alert = InfoAlertController(title: NSLocalizedString("Outage Status Details", comment: ""),
                                            message: message)
            tabBarController?.present(alert, animated: true)
        case .nonPayment:
            tabBarController?.selectedIndex = 1
        }
    }
}


// MARK: - Text View Link Delegate

extension OutageViewController: DataDetectorTextViewLinkTapDelegate {
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        GoogleAnalytics.log(event: .outageAuthEmergencyCall)
    }
}


// MARK: - Report Outage Delegate

extension OutageViewController: ReportOutageDelegate {
    func didReportOutage() {
        // Show Toast
        view.showToast(NSLocalizedString("Outage report received", comment: ""))
        GoogleAnalytics.log(event: .reportOutageAuthComplete)
        
        // Update Report Outage Cell
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TitleSubTitleRow else { return }
        cell.updateSubTitle(viewModel.outageReportedDateString)
    }
}
