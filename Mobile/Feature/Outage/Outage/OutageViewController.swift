//
//  NewOutageViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class OutageViewController: AccountPickerViewController {
    enum State {
        case normal
        case loading
        case gasOnly
        case maintenance
        case noNetwork
        case unavailable
    }
    
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
    
    private let viewModel = OutageViewModel(accountService: ServiceFactory.createAccountService(),
                                            outageService: ServiceFactory.createOutageService(),
                                            authService: ServiceFactory.createAuthenticationService())
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureAccountPicker()
        
        configureTableView()
        
        configureTableHeaderFooterView()

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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let vc = segue.destination as? ReportOutageViewController {
//            vc.viewModel.outageStatus = viewModel.currentOutageStatus!
//            if let phone = viewModel.currentOutageStatus!.contactHomeNumber {
//                vc.viewModel.phoneNumber.value = phone
//            }
//
//            // Show a toast only after an outage is reported from this workflow
//            RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
//                .drive(onNext: { [weak self] in
//                    guard let this = self else { return }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
//                        this.view.showToast(NSLocalizedString("Outage report received", comment: ""))
//                        Analytics.log(event: .reportOutageAuthComplete)
//                    })
//                })
//                .disposed(by: vc.disposeBag)
//        
//            
            
        if let vc = segue.destination as? ReportOutageViewController {
            if let outageStatus = viewModel.outageStatus {
                vc.viewModel.outageStatus = outageStatus
            }
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
        
        tableView.addSubview(refreshControl)

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
                    cell.isEnabled = !outageStatus.flagNoPay
                }
                
                self.outageStatusView.setOutageStatus(outageStatus,
                                                      reportedResults: self.viewModel.reportedOutage,
                                                      hasJustReported: self.viewModel.hasJustReportedOutage)
            }
            }, onError: { [weak self] serviceError in
                if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                    self?.configureState(.noNetwork)
                } else if serviceError.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue {
                   self?.configureState(.unavailable)
                }
            }, onMaintenance: { [weak self] in
                self?.configureState(.maintenance)
        })
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
            cell.configure(image: UIImage(named: "ic_reportoutage"), title: "Report Outage", detail: nil)
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
            Analytics.log(event: .viewStreetlightMapOfferComplete)
            performSegue(withIdentifier: "outageMapSegue", sender: true)
        case 2:
            Analytics.log(event: .viewMapOfferComplete)
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
        Analytics.log(event: .outageAuthEmergencyCall)
    }
}
