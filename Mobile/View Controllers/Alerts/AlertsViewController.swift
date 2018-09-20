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

    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!
    
    @IBOutlet weak var topStackView: UIStackView!

    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var preferencesButton: ButtonControl!
    @IBOutlet weak var preferencesButtonLabel: UILabel!
    @IBOutlet weak var alertsEmptyStateView: UIView!
    @IBOutlet weak var alertsEmptyStateLabel: UILabel!

    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let viewModel = AlertsViewModel(accountService: ServiceFactory.createAccountService())
    
    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundView.backgroundColor = .white
        
        if Environment.shared.opco == .bge {
            self.accountPicker.isHidden = true
            self.view.backgroundColor = .primaryColor
        } else {
            self.view.backgroundColor = .primaryColorAccountPicker
        }

        tableView.separatorColor = .accentGray

        styleViews()
        bindViewModel()
        
        NotificationCenter.default.rx.notification(.didChangeBudgetBillingEnrollment, object: nil)
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                // Clear account detail, which would force a refresh (in the .readyToFetchData block below) when the screen appears
                self?.viewModel.currentAccountDetail = nil
            })
            .disposed(by: disposeBag)

        accountPicker.delegate = self
        accountPicker.parentViewController = self
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                self.viewModel.isFetchingAccountDetail.value = true
                break
            case .readyToFetchData:
                if Environment.shared.opco == .bge || AccountsStore.shared.accounts.count == 1 {
                    self.accountPicker.isHidden = true
                    self.view.backgroundColor = .primaryColor
                } else {
                    self.view.backgroundColor = .primaryColorAccountPicker
                }
                
                if AccountsStore.shared.currentAccount != self.accountPicker.currentAccount {
                    self.viewModel.fetchData()
                } else if self.viewModel.currentAccountDetail == nil {
                    self.viewModel.fetchData()
                }
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setColoredNavBar(hidesBottomBorder: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the table header view
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
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
        alertsEmptyStateLabel.font = OpenSans.regular.of(textStyle: .title1)
        alertsEmptyStateLabel.text = NSLocalizedString("You haven't received any\nnotifications yet.", comment: "")
    }
    
    private func bindViewModel() {
        noNetworkConnectionView.reload
            .subscribe(onNext: { [weak self] in self?.viewModel.fetchData() })
            .disposed(by: disposeBag)
        
        viewModel.shouldShowLoadingIndicator.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowErrorLabel.not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowNoNetworkConnectionView.not().drive(noNetworkConnectionView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowNoNetworkConnectionView.drive(backgroundView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowNoNetworkConnectionView.drive(topStackView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.shouldShowAlertsTableView.not().drive(tableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowAlertsEmptyState.not().drive(alertsEmptyStateView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowAlertsEmptyState.asObservable().subscribe(onNext: { [weak self] shouldShow in
            self?.tableView.isScrollEnabled = !shouldShow
        }).disposed(by: disposeBag)

        viewModel.reloadAlertsTableViewEvent.asObservable().subscribe(onNext: { [weak self] in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        viewModel.a11yScreenChangedEvent.asObservable().subscribe(onNext: { [weak self] in
            UIAccessibility.post(notification: .screenChanged, argument: self?.view)
        }).disposed(by: disposeBag)
    }
    
    @IBAction func onPreferencesButtonTap(_ sender: Any) {
        Analytics.log(event: .alertsMainScreen)
        performSegue(withIdentifier: "preferencesSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AlertPreferencesViewController {
            vc.delegate = self
            vc.viewModel.accountDetail = viewModel.currentAccountDetail!
        }
    }
    
}

extension AlertsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.currentAlerts.value.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tableView {
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
        Analytics.log(event: .alertsPrefCenterComplete)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Preferences saved", comment: ""))
        })
    }
}
