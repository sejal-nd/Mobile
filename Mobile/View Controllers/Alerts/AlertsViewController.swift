//
//  AlertsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertsViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var segmentedControl: AlertsSegmentedControl!
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var alertsTableView: UITableView!
    @IBOutlet weak var preferencesButton: ButtonControl!
    @IBOutlet weak var preferencesButtonLabel: UILabel!
    @IBOutlet weak var alertsEmptyStateView: UIView!
    @IBOutlet weak var alertsEmptyStateLabel: UILabel!
    
    @IBOutlet weak var updatesTableView: UITableView!
    @IBOutlet weak var updatesEmptyStateView: UIView!
    @IBOutlet weak var updatesEmptyStateLabel: UILabel!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let viewModel = AlertsViewModel(accountService: ServiceFactory.createAccountService(), alertsService: ServiceFactory.createAlertsService())
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .primaryColor
        
        segmentedControl.setItems(leftLabel: NSLocalizedString("My Alerts", comment: ""),
                                  rightLabel: NSLocalizedString("Updates", comment: ""),
                                  initialSelectedIndex: 0)
        
        if Environment.sharedInstance.opco == .bge {
            accountPicker.isHidden = true
        }
        
        alertsTableView.separatorColor = .accentGray
        updatesTableView.backgroundColor = .softGray
        updatesTableView.contentInset = UIEdgeInsetsMake(22, 0, 22, 0)
        
        styleViews()
        bindViewModel()
        
        NotificationCenter.default.rx.notification(.DidChangeBudgetBillingEnrollment, object: nil)
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                // Clear account detail, which would force a refresh (in the .readyToFetchData block below) when the screen appears
                self?.viewModel.currentAccountDetail = nil
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.DidTapOnPushNotification, object: nil)
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.fetchAlertsFromDisk()
            })
            .disposed(by: disposeBag)
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                self.viewModel.isFetchingAccountDetail.value = true
                self.viewModel.isFetchingUpdates.value = true
                break
            case .readyToFetchData:
                self.viewModel.fetchAlertsFromDisk()
                if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                    self.viewModel.fetchData()
                } else if self.viewModel.currentAccountDetail == nil {
                    self.viewModel.fetchData()
                }
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the table header view
        if let headerView = alertsTableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                alertsTableView.tableHeaderView = headerView
            }
        }
    }
    
    private func styleViews() {
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        preferencesButtonLabel.textColor = .actionBlue
        preferencesButtonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        preferencesButtonLabel.text = NSLocalizedString("Preferences", comment: "")
        preferencesButton.accessibilityLabel = preferencesButtonLabel.text
        
        alertsEmptyStateLabel.textColor = .middleGray
        alertsEmptyStateLabel.font = OpenSans.regular.of(size: 18)
        alertsEmptyStateLabel.text = NSLocalizedString("You haven't received any\nnotifications yet.", comment: "")
        
        updatesEmptyStateLabel.textColor = .middleGray
        updatesEmptyStateLabel.font = OpenSans.regular.of(size: 18)
        updatesEmptyStateLabel.text = NSLocalizedString("There are no updates at\nthis time.", comment: "")
    }
    
    private func bindViewModel() {
        segmentedControl.selectedIndex.asObservable().bind(to: viewModel.selectedSegmentIndex).disposed(by: disposeBag)
        segmentedControl.selectedIndex.asObservable().distinctUntilChanged().subscribe(onNext: { index in
            if index == 1 { // User tapped on "Updates"
                Analytics().logScreenView(AnalyticsPageView.AlertsOpCoUpdate.rawValue)
            }
        }).disposed(by: disposeBag)
        
        viewModel.backgroundViewColor.drive(backgroundView.rx.backgroundColor).disposed(by: disposeBag)
        
        viewModel.shouldShowLoadingIndicator.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowErrorLabel.not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.shouldShowAlertsTableView.not().drive(alertsTableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowAlertsEmptyState.not().drive(alertsEmptyStateView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowAlertsEmptyState.asObservable().subscribe(onNext: { [weak self] shouldShow in
            self?.alertsTableView.isScrollEnabled = !shouldShow
        }).disposed(by: disposeBag)
        
        viewModel.shouldShowUpdatesTableView.not().drive(updatesTableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowUpdatesEmptyState.not().drive(updatesEmptyStateView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.reloadAlertsTableViewEvent.asObservable().subscribe(onNext: { [weak self] in
            self?.alertsTableView.reloadData()
        }).disposed(by: disposeBag)
        viewModel.reloadUpdatesTableViewEvent.asObservable().subscribe(onNext: { [weak self] in
            self?.updatesTableView.reloadData()
        }).disposed(by: disposeBag)
        viewModel.a11yScreenChangedEvent.asObservable().subscribe(onNext: { [weak self] in
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self?.view)
        }).disposed(by: disposeBag)
    }
    
    @IBAction func onPreferencesButtonTap(_ sender: Any) {
        Analytics().logScreenView(AnalyticsPageView.AlertsMainScreen.rawValue)
        performSegue(withIdentifier: "preferencesSegue", sender: self)
    }
    
    @objc func onUpdateCellTap(sender: ButtonControl) {
        performSegue(withIdentifier: "opcoUpdateDetailSegue", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AlertPreferencesViewController {
            vc.delegate = self
            vc.viewModel.accountDetail = viewModel.currentAccountDetail!
        } else if let vc = segue.destination as? OpcoUpdateDetailViewController, let button = sender as? ButtonControl {
            vc.opcoUpdate = viewModel.currentOpcoUpdates.value![button.tag]
        }
    }
    

}

extension AlertsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == alertsTableView {
            return 1
        }
        if tableView == updatesTableView {
            if let opcoUpdates = viewModel.currentOpcoUpdates.value {
                return opcoUpdates.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == alertsTableView {
            return viewModel.currentAlerts.value.count
        }
        if tableView == updatesTableView {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if tableView == alertsTableView {
            return 0.01
        } else {
            return 10
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == alertsTableView {
            var cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell")
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: "AlertCell")
            }
            
            cell!.textLabel?.numberOfLines = 0
            cell!.detailTextLabel?.numberOfLines = 0
            
            cell!.textLabel?.textColor = .deepGray
            cell!.textLabel?.font = SystemFont.regular.of(textStyle: .headline)
            cell!.textLabel?.text = viewModel.currentAlerts.value[indexPath.row].message
            
            return cell!
        }
        if tableView == updatesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UpdatesCell", for: indexPath) as! UpdatesTableViewCell
            cell.titleLabel.text = viewModel.currentOpcoUpdates.value![indexPath.section].title
            cell.detailLabel.text = viewModel.currentOpcoUpdates.value![indexPath.section].message
            
            cell.innerContentView.tag = indexPath.section
            cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
            cell.innerContentView.addTarget(self, action: #selector(onUpdateCellTap(sender:)), for: .touchUpInside)
            
            cell.innerContentView.accessibilityLabel = "\(cell.titleLabel.text ?? ""): \(cell.detailLabel.text ?? "")"
            
            return cell
        }
        return UITableViewCell()
    }
}

extension AlertsViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchAlertsFromDisk()
        viewModel.fetchData()
    }
}

extension AlertsViewController: AlertPreferencesViewControllerDelegate {
    
    func alertPreferencesViewControllerDidSavePreferences(_ alertPreferencesViewController: AlertPreferencesViewController) {
        Analytics().logScreenView(AnalyticsPageView.AlertsPrefCenterComplete.rawValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Preferences saved", comment: ""))
        })
    }
}
