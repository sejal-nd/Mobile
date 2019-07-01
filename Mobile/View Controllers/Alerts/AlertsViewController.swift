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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var preferencesButton: ButtonControl!
    @IBOutlet weak var preferencesButtonLabel: UILabel!
    @IBOutlet weak var alertsEmptyStateView: UIView!
    @IBOutlet weak var alertsEmptyStateLabel: UILabel!
    
    var shortcutToPrefs = false
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let viewModel = AlertsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("My Alerts", comment: "")
        
        tableView.backgroundColor = .white
        tableView.separatorColor = .accentGray
        tableView.isHidden = true
    
        styleViews()
        bindViewModel()
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shortcutToPrefs = false
    }
    
    private func styleViews() {
        if StormModeStatus.shared.isOn {
            view.backgroundColor = .stormModeBlack
        }
        
        preferencesButtonLabel.textColor = .actionBlue
        preferencesButtonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        preferencesButtonLabel.text = NSLocalizedString("Preferences", comment: "")
        preferencesButton.accessibilityLabel = preferencesButtonLabel.text
        
        alertsEmptyStateLabel.textColor = .middleGray
        alertsEmptyStateLabel.font = OpenSans.regular.of(textStyle: .title1)
        alertsEmptyStateLabel.text = NSLocalizedString("You haven't received any\nnotifications yet.", comment: "")
    }
    
    private func bindViewModel() {
        viewModel.shouldShowAlertsEmptyState.not()
            .drive(alertsEmptyStateView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.shouldShowAlertsEmptyState.not()
            .drive(tableView.rx.isScrollEnabled)
            .disposed(by: disposeBag)

        viewModel.currentAlerts.asDriver()
            .distinctUntilChanged()
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    private func loadAlerts() {
        tableView.isHidden = false
        
        if AccountsStore.shared.accounts.count == 1 || Environment.shared.opco == .bge {
            accountPicker.isHidden = true
        }
        
        viewModel.fetchAlertsFromDisk()
        
        // Don't push straight to prefs for ComEd/PECO multi-account users
        if shortcutToPrefs && (Environment.shared.opco == .bge || AccountsStore.shared.accounts.count == 1) {
            performSegue(withIdentifier: "preferencesSegue", sender: nil)
        }
        
        shortcutToPrefs = false
    }
    
    @IBAction func onPreferencesButtonTap(_ sender: Any) {
        Analytics.log(event: .alertsMainScreen)
        performSegue(withIdentifier: "preferencesSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AlertPreferencesViewController {
            vc.delegate = self
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
        loadAlerts()
    }
    
}

extension AlertsViewController: AlertPreferencesViewControllerDelegate {
    
    func alertPreferencesViewControllerDidSavePreferences() {
        Analytics.log(event: .alertsPrefCenterComplete)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Preferences saved", comment: ""))
        })
    }
}
