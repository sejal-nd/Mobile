//
//  AlertsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

let testAlerts = [
    "Outage to area 1215 E Fort Ave analyzed. The probable cause is unknown. Estimated restoration time 8/22/17 at 9:00 PM",
    "Severe thunderstorms in 1215 E Fort Ave from 2:00 PM to 5:00 PM. Be prepared for possible outages.",
    "Payment for account ending in 1234. Amount of $150.50 is due on 7/22/17."
]

let testUpdates = [
    ("BGE Update", "NOTICE OF EVENING HEARINGS FOR PUBLIC COMMENT - CASE NO. 9406 – Evening hearings for discussion about the price of electricity and gas in Baltimore."),
    ("Restoration Update", "Power has been restored to area 1215 E Fort Ave on 4/18/17 at 9:00 PM. Our crew is still at the location working very hard to get you power so you can watch TV."),
]

class AlertsViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var segmentedControl: AlertsSegmentedControl!
    
    @IBOutlet weak var alertsTableView: UITableView!
    @IBOutlet weak var preferencesButton: ButtonControl!
    @IBOutlet weak var preferencesButtonLabel: UILabel!
    
    @IBOutlet weak var updatesTableView: UITableView!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let viewModel = AlertsViewModel(accountService: ServiceFactory.createAccountService())
    
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
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                self.viewModel.isFetching.value = true
                break
            case .readyToFetchData:
                print("Alerts Root Screen - Fetch Data")
                if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                    self.viewModel.fetchAccountDetail()
                } else if self.viewModel.currentAccountDetail == nil {
                    self.viewModel.fetchAccountDetail()
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
        preferencesButtonLabel.textColor = .actionBlue
        preferencesButtonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        preferencesButtonLabel.text = NSLocalizedString("Preferences", comment: "")
    }
    
    private func bindViewModel() {
        segmentedControl.selectedIndex.asObservable().bind(to: viewModel.selectedSegmentIndex).disposed(by: disposeBag)
        
        viewModel.isFetching.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.shouldShowAlertsTableView.not().drive(alertsTableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowUpdatesTableView.not().drive(updatesTableView.rx.isHidden).disposed(by: disposeBag)
    }
    
    @IBAction func onPreferencesButtonTap(_ sender: Any) {
        performSegue(withIdentifier: "preferencesSegue", sender: self)
    }
    
    func onUpdateCellTap(sender: ButtonControl) {
        print("Update cell at index \(sender.tag) tapped")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AlertPreferencesViewController {
            vc.delegate = self
            vc.viewModel.accountDetail = viewModel.currentAccountDetail!
        }
    }
    

}

extension AlertsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == alertsTableView {
            return 1
        } else {
            return testUpdates.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == alertsTableView {
            return testAlerts.count
        } else {
            return 1
        }
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
            cell!.textLabel?.text = testAlerts[indexPath.row]
            
            return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UpdatesCell", for: indexPath) as! UpdatesTableViewCell
            cell.titleLabel.text = testUpdates[indexPath.section].0
            cell.detailLabel.text = testUpdates[indexPath.section].1
            
            cell.innerContentView.tag = indexPath.section
            cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
            cell.innerContentView.addTarget(self, action: #selector(onUpdateCellTap(sender:)), for: .touchUpInside)
            
            return cell
        }
    }
}

extension AlertsViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchAccountDetail()
    }
}

extension AlertsViewController: AlertPreferencesViewControllerDelegate {
    
    func alertPreferencesViewControllerDidSavePreferences(_ alertPreferencesViewController: AlertPreferencesViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Preferences saved", comment: ""))
        })
    }
}
